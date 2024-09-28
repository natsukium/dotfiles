{
  imports = (
    builtins.map (module: ./. + "/${module}") (
      builtins.filter (x: x != "default.nix") (builtins.attrNames (builtins.readDir ./.))
    )
  );
}
