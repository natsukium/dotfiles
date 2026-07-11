{ config, ... }:
let
  inherit (config.my) username;
in
{
  imports = [ ../common.nix ];

  my.profiles.development.enable = true;
  my.nix.enable = true;

  targets.genericLinux.enable = true;
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };
  nixpkgs.config.allowUnfreePredicate = pkg: true;
}
