{ pkgs, ... }:
{
  imports = [
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../vscode
    ../modules/home-manager/wallpaper.nix
  ];
}
