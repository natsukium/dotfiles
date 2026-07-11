{ config, ... }:
{
  imports = [
    ../../../systems/darwin/common.nix
    ../../../systems/darwin/desktop.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  my.profiles.base.enable = true;
  my.profiles.desktop.enable = true;
  my.profiles.development.enable = true;

  my.home.enable = true;
  home-manager.users.${config.my.username}.imports = [
    ../../../homes/darwin/common.nix
    ../../../homes/darwin/desktop.nix
  ];

  users.users.${config.my.username}.uid = 502;

  networking = {
    hostName = "katavi";
    knownNetworkServices = [ "Wi-Fi" ];
  };

  my.services.timemachine.enableLocalSnapshot = true;
}
