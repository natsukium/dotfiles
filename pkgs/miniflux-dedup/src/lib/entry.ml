(** The fields of a Miniflux entry that the sweep reasons about. Entry bodies
    are deliberately dropped here: they dominate the API response and nothing
    downstream looks at them. *)

(** Miniflux reports [read], [unread] and [removed], but the sweep only ever
    asks "may this be silenced?", so everything that is not unread collapses
    into one constructor. *)
type status = Unread | Settled

type t = { id : int; feed_id : int; url : string; status : status }

let status_of_string = function "unread" -> Unread | _ -> Settled

let of_json json =
  let open Yojson.Safe.Util in
  {
    id = json |> member "id" |> to_int;
    feed_id = json |> member "feed_id" |> to_int;
    url = json |> member "url" |> to_string;
    status = json |> member "status" |> to_string |> status_of_string;
  }

(** Decode one page of [GET /v1/entries], whose payload wraps the array in an
    [entries] field. *)
let list_of_json json =
  let open Yojson.Safe.Util in
  json |> member "entries" |> to_list |> List.map of_json

(** How many entries match the filter in total, which the API reports ignoring
    [limit] and [offset]. Reading it off the first page is what lets the caller
    name every remaining page up front instead of discovering the end one round
    trip at a time. *)
let total_of_json json =
  let open Yojson.Safe.Util in
  json |> member "total" |> to_int
