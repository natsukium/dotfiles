{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (inputs) nix-colors paneru sops-nix;
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
    paneru.homeModules.paneru
    ../modules/home-manager
    ../applications/atuin
    ../applications/gh-dash
    ../applications/misc
    ../applications/rbw
    ../applications/tmux
  ];
}
