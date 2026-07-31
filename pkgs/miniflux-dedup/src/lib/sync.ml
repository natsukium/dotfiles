let entries_path = "/v1/entries"
let page_size = 500

let page_request ~published_after ~offset =
  ( entries_path,
    [
      ("published_after", string_of_int published_after);
      ("limit", string_of_int page_size);
      ("offset", string_of_int offset);
      ("order", "id");
      ("direction", "asc");
    ] )

(** Read the whole window.

    The first response carries the total matching count, so every remaining page
    can be named up front and handed over as a single batch instead of being
    discovered one round trip at a time. Naming them together is what lets the
    handler collect them concurrently while this module stays unaware that any
    scheduler exists.

    Entries created after that first response are missed by this sweep. Sorting
    by ascending id is what makes that safe: they land past the last offset
    rather than shifting rows into a page already read, so the next run picks
    them up. *)
let fetch ~published_after =
  let first =
    match Api.fetch [ page_request ~published_after ~offset:0 ] with
    | [ page ] -> page
    | pages ->
        Printf.ksprintf failwith "expected one page, got %d" (List.length pages)
  in
  let pages_left =
    ((Entry.total_of_json first + page_size - 1) / page_size) - 1
  in
  let rest =
    if pages_left <= 0 then []
    else
      Api.fetch
        (List.init pages_left (fun index ->
             page_request ~published_after ~offset:((index + 1) * page_size)))
  in
  let pages = first :: rest in
  (List.length pages, List.concat_map Entry.list_of_json pages)

type report = {
  pages : int;
  scanned : int;
  window_from : int;
  marked : int list;
}
(** What a sweep did, returned rather than printed so that the operator-facing
    wording lives at the edge in [bin/] and the suite can assert on the facts
    themselves instead of capturing stdout.

    [marked] carries the ids and not just a count because marking an article
    read hides it before it was ever seen: when the sweep silences the wrong
    copy, the journal is the only place left to find out which. *)

(** Sweep one window.

    [now] is a parameter rather than a call into the clock so that the window
    boundary is reproducible under test. *)
let run ~now ~window_days =
  let window_from = now - (window_days * 86400) in
  let pages, entries = fetch ~published_after:window_from in
  let marked = Dedup.duplicates entries in
  (* Staying silent when there is nothing to do matters: Miniflux rejects an
     update carrying an empty id list as a bad request. *)
  if marked <> [] then
    (* One bulk request: Miniflux accepts the whole id list at once, and a
       request per entry would multiply round trips for no gain. *)
    Api.put ~path:entries_path
      ~body:
        (`Assoc
           [
             ("entry_ids", `List (List.map (fun id -> `Int id) marked));
             ("status", `String "read");
           ]);
  { pages; scanned = List.length entries; window_from; marked }
