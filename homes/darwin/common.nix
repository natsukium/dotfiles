# Shared Home Manager layer for the darwin desktops (katavi, work): a docker
# client backed by a colima VM. The Home Manager scaffolding and the base home
# config now come from the home-manager module (my.home.enable); each darwin
# host imports this file into its user's home config.
{ lib, pkgs, ... }:
{
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
}
