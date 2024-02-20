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
    ../applications/gh-dash
    ../applications/gitui
    ../applications/lazygit
    ../applications/nvim
    ../applications/rbw
    ../alacritty
    ../bash
    ../fish
    ../ghq
    ../git
    ../nix
    ../starship
    ../tmux
    ../vim
    ../misc
  ];
}
