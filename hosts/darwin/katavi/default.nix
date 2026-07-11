{ config, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../../../systems/darwin/common.nix
    ../../../systems/darwin/desktop.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  my.home.enable = true;
  home-manager.users.${config.my.username}.imports = [
    ../../../homes/darwin/common.nix
    ../../../homes/darwin/desktop.nix
    ../../../modules/profiles/home/base.nix
    ../../../modules/profiles/home/desktop.nix
    ../../../modules/profiles/home/development.nix
  ];

  users.users.${config.my.username}.uid = 502;

  networking = {
    hostName = "katavi";
    knownNetworkServices = [ "Wi-Fi" ];
  };

  my.services.timemachine.enableLocalSnapshot = true;
}
