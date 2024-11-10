{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ../desktop.nix
  ];

  networking.hostName = "katavi";
}
