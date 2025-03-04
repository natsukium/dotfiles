{ lib, specialArgs, ... }:
{
  imports = [
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  system.stateVersion = 6;
}
