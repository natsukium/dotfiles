# Home Manager wiring, injected into every system host via the registry.
#
# The Home Manager system module is imported unconditionally, because an import
# cannot be gated on `config`; everything with an effect instead sits behind
# my.home.enable. So a server that leaves the toggle off is byte-identical to one
# that never saw this module: Home Manager with no configured users adds nothing
# to the closure.
{ inputs, config, ... }:
let
  homeManagerModules = builtins.attrValues config.flake.modules.homeManager;

  mkModule =
    homeManagerSystemModule:
    { config, lib, ... }:
    {
      imports = [ homeManagerSystemModule ];

      options.my.home.enable = lib.mkEnableOption "Home Manager for the primary user";

      config = lib.mkIf config.my.home.enable {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs; };
          sharedModules = homeManagerModules;
          users.${config.my.username}.imports = [ ../../homes/common.nix ];
        };
      };
    };
in
{
  flake.modules.nixos.home-manager = mkModule inputs.home-manager.nixosModules.home-manager;
  flake.modules.darwin.home-manager = mkModule inputs.home-manager.darwinModules.home-manager;
}
