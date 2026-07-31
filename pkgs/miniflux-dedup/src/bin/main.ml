(** The transport half of the sweep: everything that touches the network lives
    here, installed as a handler for the effects [Miniflux_dedup.Api] declares.

    This is also where the choice to fetch pages concurrently is made. The sweep
    hands over a batch of requests and says nothing about scheduling, which is
    what makes Eio's presence a decision local to this file. *)

let require name =
  match Sys.getenv_opt name with
  | Some value -> value
  | None -> failwith (name ^ " is not set")

(* The unit talks to miniflux on the loopback port, so the reverse proxy and
   its TLS are not in the way; MINIFLUX_URL exists to point a manual run
   somewhere else. *)
let base_url =
  Option.value ~default:"http://localhost:8080" (Sys.getenv_opt "MINIFLUX_URL")

let window_days =
  match Sys.getenv_opt "MINIFLUX_DEDUP_WINDOW_DAYS" with
  | Some value -> int_of_string value
  | None -> 3

(* Enough to make a wide backlog sweep worth parallelising without opening a
   connection per page: cohttp-eio pools nothing, so every fiber costs a
   socket. *)
let max_connections = 8

(* journald truncates a long line rather than wrapping it, so the id trail is
   emitted in bounded pieces. *)
let ids_per_line = 100

let main () =
  (* Miniflux accepts basic auth on the API, which lets the sweep reuse the
     credentials file the server itself already consumes instead of needing a
     per-application key provisioned by hand. *)
  let credentials =
    `Basic (require "ADMIN_USERNAME", require "ADMIN_PASSWORD")
  in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let client = Cohttp_eio.Client.make ~https:None (Eio.Stdenv.net env) in
  let headers =
    Cohttp.Header.add_authorization (Http.Header.init ()) credentials
  in
  let endpoint path query =
    Uri.with_query' (Uri.of_string (base_url ^ path)) query
  in
  let read (response, body) =
    (* Eio wants a ceiling up front; entry bodies make responses large enough
       that any figure picked here would be a guess, and the peer is a local
       process we already trust. *)
    let text = Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int in
    let code = Http.Status.to_int (Http.Response.status response) in
    if code >= 200 && code < 300 then text
    else failwith (Printf.sprintf "miniflux answered %d: %s" code text)
  in
  let get_json (path, query) =
    Yojson.Safe.from_string
      (read (Cohttp_eio.Client.get ~sw ~headers client (endpoint path query)))
  in
  let over_http body =
    Effect.Deep.match_with body ()
      {
        retc = Fun.id;
        exnc = raise;
        effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Miniflux_dedup.Api.Fetch requests ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    Effect.Deep.continue k
                      (Eio.Fiber.List.map ~max_fibers:max_connections get_json
                         requests))
            | Miniflux_dedup.Api.Put (path, json) ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let headers =
                      Http.Header.add headers "Content-Type" "application/json"
                    in
                    let body =
                      Cohttp_eio.Body.of_string (Yojson.Safe.to_string json)
                    in
                    ignore
                      (read
                         (Cohttp_eio.Client.put ~sw ~headers ~body client
                            (endpoint path [])));
                    Effect.Deep.continue k ())
            (* Eio's own effects belong to the scheduler outside this handler
               and must keep travelling outwards. *)
            | _ -> None);
      }
  in
  let now = int_of_float (Eio.Time.now (Eio.Stdenv.clock env)) in
  let report =
    over_http (fun () -> Miniflux_dedup.Sync.run ~now ~window_days)
  in
  Printf.printf
    "scanned %d entries over %d page(s), window %d days (published_after %d)\n"
    report.scanned report.pages window_days report.window_from;
  Printf.printf "marked %d entries as read\n" (List.length report.marked);
  (* The ids go out in chunks so that a backlog sweep, which can silence
     thousands at once, is not quietly cut short by journald's line limit --
     the point of recording them is that they survive to be looked up. *)
  List.iteri
    (fun index id ->
      if index mod ids_per_line = 0 then (
        if index > 0 then print_newline ();
        print_string "marked read:");
      Printf.printf " %d" id)
    report.marked;
  if report.marked <> [] then print_newline ()

let () =
  (* Every failure raised here is deliberate and says in its message what went
     wrong, so it reaches the journal as a single readable line. A backtrace
     would bury it under thirty frames of Eio scheduler. Anything else is
     unforeseen, and there the location is the only clue there is. *)
  Printexc.record_backtrace true;
  match main () with
  | () -> ()
  | exception Failure message ->
      prerr_endline message;
      exit 1
