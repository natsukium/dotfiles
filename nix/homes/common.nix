{
  pkgs,
  lib,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isWsl;
  inherit (specialArgs.inputs) nix-colors;
in {
  programs.home-manager.enable = true;
  home = {
    stateVersion = "22.11";
  };

  colorScheme = nix-colors.colorSchemes.nord;

  imports =
    [
      nix-colors.homeManagerModule
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
    ]
    ++ lib.optional (! isWsl) ../vscode;
}
