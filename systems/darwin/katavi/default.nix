{ pkgs, specialArgs, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  users.users.${specialArgs.username}.uid = 502;

  networking = {
    hostName = "katavi";
    knownNetworkServices = [ "Wi-Fi" ];
  };

  my.services.timemachine.enableLocalSnapshot = true;
}
