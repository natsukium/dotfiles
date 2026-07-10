# An option rather than the `username` specialArg it replaces: registry modules
# must stay evaluable outside this flake, where specialArgs are not injected.
# Registered in every class so the system and Home Manager evaluations share it.
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
