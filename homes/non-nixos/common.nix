{ config, ... }:
let
  inherit (config.my) username;
in
{
  imports = [
    ../../modules/profiles/home/development.nix
    ../../modules/profiles/home/generic-linux.nix
    ../common.nix
  ];

  targets.genericLinux.enable = true;
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };
  nixpkgs.config.allowUnfreePredicate = pkg: true;
}
