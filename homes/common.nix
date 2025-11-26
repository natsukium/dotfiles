{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (inputs) nix-colors sops-nix zen-browser;
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

  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  imports = [
    nix-colors.homeManagerModule
    sops-nix.homeManagerModules.sops
    ../modules/home-manager
    ../applications/atuin
    ../applications/bash
    ../applications/fish
    ../applications/gh-dash
    ../applications/git
    ../applications/lazygit
    ../applications/misc
    ../applications/newsboat
    ../applications/nushell
    ../applications/rbw
    ../applications/starship
    ../applications/tmux
    ../applications/vim
  ];
}
