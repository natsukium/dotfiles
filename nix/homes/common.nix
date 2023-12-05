{specialArgs, ...}: let
  inherit (specialArgs.inputs) nix-colors;
in {
  programs.home-manager.enable = true;
  home = {
    stateVersion = "22.11";
  };

  inherit (specialArgs) colorScheme;
  base16.enable = true;

  imports = [
    nix-colors.homeManagerModule
    ../modules/base16.nix
    ../applications/gh-dash
    ../applications/gitui
    ../applications/lazygit
    ../applications/nvim
    ../applications/rbw
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
