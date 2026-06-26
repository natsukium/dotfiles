{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.my) username;
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Home Manager registry modules cross into every user's evaluation here;
    # the system registry is injected by the host loader.
    sharedModules = builtins.attrValues inputs.self.modules.homeManager;
    users.${username} = {
      imports = [
        ../common.nix
      ];

      services.colima = {
        enable = true;
        profiles.default.settings = {
          cpu = 8;
          memory = 8;
          runtime = "docker";
        }
        // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64) {
          vmType = "vz";
          mountType = "virtiofs";
          rosetta = true;
        };
      };

      home.packages = with pkgs; [
        docker-client
        docker-buildx
        # without this, the older builtin `less` would be used
        less
      ];
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
