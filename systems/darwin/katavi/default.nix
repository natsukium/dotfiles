{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  networking.hostName = "katavi";
}
