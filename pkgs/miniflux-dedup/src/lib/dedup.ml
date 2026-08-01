(** Miniflux deduplicates within a feed only -- its uniqueness key is
    [(feed_id, hash)] -- so an article syndicated by two feeds is stored twice
    by design, and cross-feed deduplication has sat unimplemented upstream since
    2020 (miniflux/v2#797).

    The article URL is the discriminator rather than the title: NHK delivers one
    article to several category feeds under a byte-identical URL, and keeps
    editing it under that URL, so two feeds fetched minutes apart can hold the
    same article under different headlines. Comparing titles would miss those,
    while the URL identifies the article exactly. *)

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

let is_unread (entry : Entry.t) =
  match entry.status with Entry.Unread -> true | Entry.Settled -> false

(** Whether some other feed already delivered this URL first.

    Two entries from the same feed are never copies of one another: miniflux
    would have collapsed them had their hashes matched, so a feed holding the
    same URL twice has asserted through distinct guids that the items differ.
    Repology does exactly this, reusing one project URL for every release it
    announces, and without the feed test those releases would silence each
    other. *)
let preceded_by_another_feed (entry : Entry.t) group =
  List.exists
    (fun (other : Entry.t) ->
      other.feed_id <> entry.feed_id && other.id < entry.id)
    group

(** The ids in one URL group that repeat what an earlier feed already offered.

    The earliest entry always survives, and which copies are read plays no part
    in choosing it. Were the survivor "whichever copy is still unread", the
    sweep's own marking would move it: having silenced one copy, the next run
    would keep a different one and silence the copy it had just kept, and the
    article would disappear over two runs. Nothing here can tell the reader's
    marks apart from its own, so the survivor is fixed by id. *)
let redundant group =
  List.filter
    (fun entry -> is_unread entry && preceded_by_another_feed entry group)
    group
  |> List.map (fun (entry : Entry.t) -> entry.id)

(** Every id that should be marked read. *)
let duplicates entries =
  Hashtbl.fold (fun _url group acc -> redundant group @ acc) (by_url entries) []
  (* Hashtbl.fold visits groups in an unspecified order, so sort before
     returning: the caller sends the ids in one request where order is
     irrelevant, but a reproducible result is what lets the suite compare
     against a literal. *)
  |> List.sort Int.compare
