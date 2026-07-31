{
  lib,
  ocaml-ng,
}:
let
  # OCaml 5.5 rather than the nixpkgs default: the suite's stub runner takes a
  # responder that has to stay polymorphic in each effect's result type, which
  # needs the polymorphic function parameters introduced in 5.5.
  ocamlPackages = ocaml-ng.ocamlPackages_5_5;
in
ocamlPackages.buildDunePackage {
  pname = "miniflux-dedup";
  version = "0.1.0";

  src = ./src;

  buildInputs = with ocamlPackages; [
    cohttp
    cohttp-eio
    eio
    eio_main
    uri
    yojson
  ];

  doCheck = true;
  checkInputs = with ocamlPackages; [
    alcotest
    qcheck
  ];

  meta = {
    description = "Mark cross-feed duplicate Miniflux entries as read";
    mainProgram = "miniflux-dedup";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
