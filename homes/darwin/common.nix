{
  inputs,
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) username;
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../common.nix
      ];

      services.colima = {
        enable = true;
        profiles.default.settings =
          {
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
