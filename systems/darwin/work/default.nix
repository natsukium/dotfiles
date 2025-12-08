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

  networking.hostName = "work";
}
