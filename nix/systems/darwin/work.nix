{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./desktop.nix
  ];

  homebrew = {
    enable = true;
    brews = [ "libomp" ];
  };
}
