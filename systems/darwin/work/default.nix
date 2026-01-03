{ lib, specialArgs, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  system.stateVersion = 6;

  my.services.timemachine.enableLocalSnapshot = true;

  networking = {
    hostName = "work";
    knownNetworkServices = [
      "USB 10/100/1G/2.5G LAN"
      "Wi-Fi"
    ];
  };
}
