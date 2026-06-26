# User identity, shared across the system and Home Manager evaluations. Kept at
# the modules/flake root as machinery (sibling of hosts.nix) rather than as a
# feature: every host depends on it and it carries no enable toggle. Replaces the
# old `username` specialArg.
{ ... }:
let
  module =
    { lib, ... }:
    {
      options.my.username = lib.mkOption {
        type = lib.types.str;
        default = "natsukium";
        description = "Primary user identity.";
      };
    };
in
{
  flake.modules.nixos.username = module;
  flake.modules.darwin.username = module;
  flake.modules.homeManager.username = module;
}
