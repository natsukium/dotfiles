{ pkgs, specialArgs, ... }:
{
  imports = [
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  users.users.${specialArgs.username}.uid = 502;

  networking.hostName = "katavi";
}
