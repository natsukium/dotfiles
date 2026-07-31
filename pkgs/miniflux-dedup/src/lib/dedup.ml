(** Miniflux deduplicates within a feed only -- its uniqueness key is
    [(feed_id, hash)] -- so an article syndicated by two feeds is stored twice
    by design, and cross-feed deduplication has sat unimplemented upstream since
    2020 (miniflux/v2#797).

    The article URL is the discriminator rather than the title: NHK republishes
    the same article under several category feeds with a byte-identical URL,
    which makes exact comparison sufficient and avoids the false positives a
    similarity threshold would bring. *)

let by_url entries =
  let groups = Hashtbl.create 64 in
  List.iter
    (fun (entry : Entry.t) ->
      (* Entries without a URL carry no evidence of being the same article, so
         they never join a group. *)
      if entry.url <> "" then
        Hashtbl.replace groups entry.url
          (entry :: Option.value ~default:[] (Hashtbl.find_opt groups entry.url)))
    entries;
  groups

(** The ids that should be marked read: within each URL group the lowest id is
    the copy Miniflux stored first and is always kept, and every later copy that
    is still unread is returned.

    Settled entries take part in the grouping without being returned, which cuts
    both ways on purpose: a duplicate arriving after the original was already
    read gets silenced, while an unread original is never displaced by a copy
    that merely happens to be read. *)
let duplicates entries =
  Hashtbl.fold
    (fun _url group acc ->
      match
        List.sort
          (fun (a : Entry.t) (b : Entry.t) -> Int.compare a.id b.id)
          group
      with
      | [] | [ _ ] -> acc
      | _earliest :: later ->
          List.filter_map
            (fun (entry : Entry.t) ->
              match entry.status with
              | Entry.Unread -> Some entry.id
              | Entry.Settled -> None)
            later
          @ acc)
    (by_url entries) []
  (* Hashtbl.fold visits groups in an unspecified order, so sort before
     returning: the caller sends the ids in one request where order is
     irrelevant, but a reproducible result is what lets the suite compare
     against a literal. *)
  |> List.sort Int.compare
