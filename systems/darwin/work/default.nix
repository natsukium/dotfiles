{ lib, specialArgs, ... }:
{
  imports = [
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  system.stateVersion = 6;

  my.services.timemachine.enableLocalSnapshot = true;

  services.comin.hostname = "work";
}
