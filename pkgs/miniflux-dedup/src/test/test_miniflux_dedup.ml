open Miniflux_dedup

let entry id url status : Entry.t = { id; url; status }
let unread id url = entry id url Entry.Unread
let settled id url = entry id url Entry.Settled
let ids = Alcotest.(list int)

(* Alcotest knows no printer for yojson, and a mismatched request body is
   unreadable without one. *)
let json =
  Alcotest.testable
    (fun fmt value -> Format.pp_print_string fmt (Yojson.Safe.to_string value))
    ( = )

let duplicates_cases =
  let case name expected entries =
    Alcotest.test_case name `Quick (fun () ->
        Alcotest.check ids name expected (Dedup.duplicates entries))
  in
  [
    case "returns the later copy of a duplicated url" [ 11 ]
      [ unread 10 "/a"; unread 11 "/a" ];
    case "silences a copy that arrives after the original was read" [ 13 ]
      [ settled 12 "/b"; unread 13 "/b" ];
    case "keeps an unread original that a read copy follows" []
      [ unread 15 "/d"; settled 16 "/d" ];
    case "leaves an article published only once alone" [] [ unread 14 "/c" ];
    case "returns every later copy when an article appears three times"
      [ 18; 19 ]
      [ unread 17 "/e"; unread 18 "/e"; unread 19 "/e" ];
    case "never groups entries that carry no url" []
      [ unread 20 ""; unread 21 "" ];
  ]

(* Ids come from the position in the list so that every generated entry has a
   distinct one: ties would leave "the earliest copy" ambiguous and the
   properties below unfalsifiable. *)
let arbitrary_entries =
  QCheck.(
    map
      (List.mapi (fun id (url, is_unread) ->
           entry id url (if is_unread then Entry.Unread else Entry.Settled)))
      (list (pair (oneof_list [ "/a"; "/b"; "/c"; "" ]) bool)))

(* Grouped here instead of calling Dedup.by_url: a property checked against the
   implementation's own grouping would still pass if the grouping is the part
   that broke. *)
let earliest_ids entries =
  List.filter (fun (e : Entry.t) -> e.url <> "") entries
  |> List.fold_left
       (fun acc (e : Entry.t) ->
         match List.assoc_opt e.url acc with
         | Some id when id <= e.id -> acc
         | _ -> (e.url, e.id) :: List.remove_assoc e.url acc)
       []
  |> List.map snd

let property name prop =
  Alcotest.test_case name `Quick (fun () ->
      QCheck.Test.check_exn
        (QCheck.Test.make ~count:500 ~name arbitrary_entries prop))

let property_cases =
  [
    property "never returns the earliest id of any url" (fun entries ->
        let marked = Dedup.duplicates entries in
        List.for_all (fun id -> not (List.mem id marked)) (earliest_ids entries));
    (* Pages arrive in whatever order the transport completed them, and
       Hashtbl.fold adds an ordering of its own, so pin down that neither leaks
       into the result. *)
    property "result does not depend on the order entries arrive in"
      (fun entries ->
        Dedup.duplicates entries = Dedup.duplicates (List.rev entries));
  ]

(* The responder has to answer [Fetch] at [Yojson.Safe.t list] and [Put] at
   [unit], so its parameter carries an explicit polymorphic annotation. Before
   OCaml 5.5 a parameter was assumed monomorphic, and this helper would have
   needed the responder wrapped in a record with a polymorphic field. *)
let with_stub (responder : 'a. 'a Effect.t -> 'a option) body =
  Effect.Deep.match_with body ()
    {
      retc = Fun.id;
      exnc = raise;
      effc =
        (fun (type a) (eff : a Effect.t) ->
          match responder eff with
          | Some reply ->
              Some
                (fun (k : (a, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue k reply)
          (* Anything unhandled -- Eio's own effects in production, a genuine
             mistake here -- keeps travelling outwards. *)
          | None -> None);
    }

let page ?total entries =
  `Assoc
    [
      ("total", `Int (Option.value ~default:(List.length entries) total));
      ( "entries",
        `List
          (List.map
             (fun (id, url, status) ->
               `Assoc
                 [
                   ("id", `Int id);
                   ("url", `String url);
                   ("status", `String status);
                 ])
             entries) );
    ]

let offsets_of requests =
  List.map
    (fun ((_ : string), query) -> int_of_string (List.assoc "offset" query))
    requests

(* Answers every fetch by offset while recording the shape of each batch, which
   is what the pagination tests assert on. *)
let sweep_recording ?(now = 0) ~respond batches =
  let responder : type a. a Effect.t -> a option = function
    | Api.Fetch requests ->
        let offsets = offsets_of requests in
        batches := offsets :: !batches;
        Some (List.map respond offsets)
    | Api.Put _ -> Some ()
    | _ -> None
  in
  with_stub responder (fun () -> Sync.run ~now ~window_days:3)

let marks_later_copy () =
  let sent = ref [] in
  let responder : type a. a Effect.t -> a option = function
    | Api.Fetch _ ->
        Some [ page [ (10, "/a", "unread"); (11, "/a", "unread") ] ]
    | Api.Put (path, body) ->
        sent := (path, body) :: !sent;
        Some ()
    | _ -> None
  in
  let report : Sync.report =
    with_stub responder (fun () -> Sync.run ~now:0 ~window_days:3)
  in
  Alcotest.check ids "ids marked" [ 11 ] report.marked;
  match !sent with
  | [ (path, body) ] ->
      Alcotest.(check string) "request path" "/v1/entries" path;
      Alcotest.check json "request body"
        (`Assoc [ ("entry_ids", `List [ `Int 11 ]); ("status", `String "read") ])
        body
  | _ -> Alcotest.fail "expected exactly one update request"

(* Miniflux rejects an update carrying an empty id list, so an uneventful sweep
   has to stay off the wire entirely rather than send one. *)
let stays_silent_when_nothing_duplicated () =
  let puts = ref 0 in
  let responder : type a. a Effect.t -> a option = function
    | Api.Fetch _ ->
        Some [ page [ (10, "/a", "unread"); (11, "/b", "unread") ] ]
    | Api.Put _ ->
        incr puts;
        Some ()
    | _ -> None
  in
  let report : Sync.report =
    with_stub responder (fun () -> Sync.run ~now:0 ~window_days:3)
  in
  Alcotest.check ids "ids marked" [] report.marked;
  Alcotest.(check int) "update requests" 0 !puts

(* Naming every outstanding page in a single batch is what allows the handler
   to fetch them concurrently, so assert the batching itself rather than just
   the offsets eventually visited. *)
let batches_the_remaining_pages () =
  let batches = ref [] in
  let total = (2 * Sync.page_size) + 1 in
  let respond _offset = page ~total [] in
  let report : Sync.report = sweep_recording ~respond batches in
  Alcotest.(check (list (list int)))
    "batches requested"
    [ [ 0 ]; [ Sync.page_size; 2 * Sync.page_size ] ]
    (List.rev !batches);
  Alcotest.(check int) "pages reported" 3 report.pages

let combines_entries_from_every_page () =
  let batches = ref [] in
  let total = Sync.page_size + 2 in
  (* A full page of distinct urls, so the only candidate pair is the one
     planted on the second page: were it dropped, nothing would be marked. *)
  let respond offset =
    if offset = 0 then
      page ~total
        (List.init Sync.page_size (fun i ->
             (i, Printf.sprintf "/filler/%d" i, "unread")))
    else page ~total [ (900, "/dup", "unread"); (901, "/dup", "unread") ]
  in
  let report : Sync.report = sweep_recording ~respond batches in
  Alcotest.check ids "ids marked" [ 901 ] report.marked;
  Alcotest.(check (list (list int)))
    "batches requested"
    [ [ 0 ]; [ Sync.page_size ] ]
    (List.rev !batches)

(* A window that fits in one page must not provoke a second, empty round trip. *)
let stops_after_a_single_page () =
  let batches = ref [] in
  let respond _offset = page [ (10, "/a", "unread") ] in
  let report : Sync.report = sweep_recording ~respond batches in
  Alcotest.(check (list (list int)))
    "batches requested" [ [ 0 ] ] (List.rev !batches);
  Alcotest.(check int) "pages reported" 1 report.pages

(* The report is what the journal line is built from, so a wrong count is a
   wrong audit trail rather than merely a cosmetic slip. *)
let reports_what_it_examined () =
  let batches = ref [] in
  let total = Sync.page_size + 3 in
  let respond offset =
    if offset = 0 then
      page ~total
        (List.init Sync.page_size (fun i ->
             (i, Printf.sprintf "/filler/%d" i, "unread")))
    else
      page ~total
        [
          (900, "/dup", "unread");
          (901, "/dup", "unread");
          (902, "/dup", "unread");
        ]
  in
  let report : Sync.report = sweep_recording ~now:1_000_000 ~respond batches in
  Alcotest.(check int) "entries scanned" (Sync.page_size + 3) report.scanned;
  Alcotest.(check int) "pages fetched" 2 report.pages;
  Alcotest.(check int)
    "window start"
    (1_000_000 - (3 * 86400))
    report.window_from;
  Alcotest.check ids "ids marked" [ 901; 902 ] report.marked

(* The window is the only reason [run] takes a clock reading at all, so pin the
   arithmetic down rather than leave a sign error to be found in production. *)
let asks_for_the_requested_window () =
  let asked = ref None in
  let responder : type a. a Effect.t -> a option = function
    | Api.Fetch requests ->
        let (_ : string), query = List.hd requests in
        asked := List.assoc_opt "published_after" query;
        Some (List.map (fun _ -> page []) requests)
    | Api.Put _ -> Some ()
    | _ -> None
  in
  ignore
    (with_stub responder (fun () -> Sync.run ~now:1_000_000 ~window_days:3));
  Alcotest.(check (option string))
    "published_after"
    (Some (string_of_int (1_000_000 - (3 * 86400))))
    !asked

let sweep_cases =
  [
    Alcotest.test_case "marks the later copy read and reports which" `Quick
      marks_later_copy;
    Alcotest.test_case "sends no request when nothing is duplicated" `Quick
      stays_silent_when_nothing_duplicated;
    Alcotest.test_case "asks for every remaining page in one batch" `Quick
      batches_the_remaining_pages;
    Alcotest.test_case "combines entries from every page" `Quick
      combines_entries_from_every_page;
    Alcotest.test_case "stops after a single page when the window fits" `Quick
      stops_after_a_single_page;
    Alcotest.test_case "reports the pages, entries and window it covered" `Quick
      reports_what_it_examined;
    Alcotest.test_case "asks for entries published within the window" `Quick
      asks_for_the_requested_window;
  ]

let () =
  Alcotest.run "miniflux-dedup"
    [
      ("duplicates", duplicates_cases);
      ("properties", property_cases);
      ("sweep", sweep_cases);
    ]
