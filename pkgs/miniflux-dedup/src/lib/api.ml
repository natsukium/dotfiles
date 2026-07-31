(** The calls the sweep makes, declared as effects instead of being passed in as
    a record of closures.

    The sweep then names no transport at all: [bin/] installs a cohttp-eio
    handler, while the suite answers the very same effects with canned payloads.
    That keeps the tests free of both an HTTP server and any injection plumbing,
    and it is why this library depends on nothing but yojson.

    [Fetch] deliberately takes a list rather than a single request. The sweep
    only states which documents it needs; whether they are collected one at a
    time or concurrently is the handler's decision, so no notion of scheduling
    reaches this library. *)

type request = string * (string * string) list

type _ Effect.t +=
  | Fetch : request list -> Yojson.Safe.t list Effect.t
  | Put : string * Yojson.Safe.t -> unit Effect.t

let fetch requests = Effect.perform (Fetch requests)
let put ~path ~body = Effect.perform (Put (path, body))
