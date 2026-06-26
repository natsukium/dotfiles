{ config, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../../../systems/darwin/common.nix
    ../../../systems/darwin/desktop.nix
    ../../../homes/darwin/common.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${config.my.username}.uid = 502;

  networking = {
    hostName = "katavi";
    knownNetworkServices = [ "Wi-Fi" ];
  };

  my.services.timemachine.enableLocalSnapshot = true;

  home-manager.users.${config.my.username}.imports = [
    ../../../modules/profiles/home/base.nix
    ../../../modules/profiles/home/desktop.nix
    ../../../modules/profiles/home/development.nix
    ../../../homes/darwin/desktop.nix
  ];
}
