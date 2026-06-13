# Entry point for the flake-parts layer: pulls in the upstream module registry
# (flake.modules.{nixos,darwin,homeManager} with _class checking) and then
# auto-imports every sibling module.
{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ]
  ++ import ../../lib/collectFlakeModules.nix ./.;
}
