{
  pkgs,
  lib,
  specialArgs,
  ...
}: let
  inherit (specialArgs.inputs) nix-colors;
in {
  programs.home-manager.enable = true;
  home = {
    stateVersion = "22.11";
  };

  colorScheme = nix-colors.colorSchemes.nord;
  base16.enable = true;

  imports =
    [
      nix-colors.homeManagerModule
      ../modules/base16.nix
      ../applications/gitui
      ../applications/nvim
      ../alacritty
      ../bash
      ../bat
      ../fish
      ../ghq
      ../git
      ../nix
      ../python
      ../starship
      ../tmux
      ../vim
      ../misc
    ];
}
