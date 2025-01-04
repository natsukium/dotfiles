{ inputs, pkgs, ... }:
let
  inherit (inputs) nix-colors;
in
{
  programs.home-manager.enable = true;
  home = {
    stateVersion = "24.11";
  };

  home.preferXdgDirectories = true;

  colorScheme = nix-colors.colorSchemes.nord;
  base16.enable = true;

  # editor
  home.packages = [
    (pkgs.callPackage ../pkgs/neovim-with-config { })
    pkgs.neovim-remote
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  imports = [
    nix-colors.homeManagerModule
    ../modules/home-manager
    ../applications/alacritty
    ../applications/atuin
    ../applications/bash
    ../applications/emacs
    ../applications/fish
    ../applications/gh-dash
    ../applications/ghq
    ../applications/git
    ../applications/gitui
    ../applications/lazygit
    ../applications/misc
    ../applications/nix
    ../applications/nushell
    ../applications/rbw
    ../applications/starship
    ../applications/tmux
    ../applications/vim
  ];
}
