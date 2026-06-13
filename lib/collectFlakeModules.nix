# Recursively discover flake-parts modules under `dir`, returning import paths.
# `default.nix` is the boundary: a directory with one is a module (imported
# whole), a directory without one is a namespace (recursed into). This lets
# feature-internal helpers (package.nix, lua/*.lua) sit beside a default.nix
# without being mistaken for top-level modules.
dir:
let
  inherit (builtins)
    readDir
    attrNames
    concatMap
    pathExists
    match
    filter
    ;
  collect =
    d:
    let
      entries = readDir d;
    in
    concatMap (
      name:
      let
        path = d + "/${name}";
      in
      if entries.${name} == "directory" then
        (if pathExists (path + "/default.nix") then [ path ] else collect path)
      else if match ".*\\.nix" name != null then
        [ path ]
      else
        [ ]
    ) (attrNames entries);
in
# Drop the starting directory's own default.nix: it is the caller, so importing
# it would recurse. Nested ones are collected as their directory, not as files.
filter (p: baseNameOf p != "default.nix") (collect dir)
