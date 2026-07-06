# The public module surface, curated in one place so a change to it shows up
# as a diff of this file rather than scattered across feature modules.
{ ... }:
{
  flake.darwinModules.forgejo-runner = ./features/forgejo-runner/darwin-module.nix;
}
