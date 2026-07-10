{ pkgs, config, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../common.nix
    ../desktop.nix
  ];

  users.users.${config.my.username}.uid = 502;

  networking = {
    hostName = "katavi";
    knownNetworkServices = [ "Wi-Fi" ];
  };

  my.services.timemachine.enableLocalSnapshot = true;
}
