{ pkgs, ... }:
{
  imports = [
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../vscode
    ../modules/home-manager/chromium.nix
    ../modules/home-manager/wallpaper.nix
  ];
}
