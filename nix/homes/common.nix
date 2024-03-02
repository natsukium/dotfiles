{ inputs, pkgs, ... }:
let
  inherit (inputs) nix-colors nur;
in
{
  programs.home-manager.enable = true;
  home = {
    stateVersion = "22.11";
  };

  colorScheme = nix-colors.colorSchemes.nord;
  base16.enable = true;

  imports = [
    nix-colors.homeManagerModule
    nur.hmModules.nur
    ../modules/home-manager
    ../applications/alacritty
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
    ../applications/nvim
    ../applications/rbw
    ../applications/starship
    ../applications/tmux
    ../applications/vim
  ];
}
