{
  inputs,
  config,
  ...
}:
let
  inherit (inputs)
    nix-colors
    paneru
    sops-nix
    self
    ;
in
{
  programs.home-manager.enable = true;
  home = {
    stateVersion = "24.11";
  };

  home.preferXdgDirectories = true;

  colorScheme = nix-colors.colorSchemes.nord;
  base16.enable = true;

  my.programs.neovim.enable = true;

  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  imports = [
    nix-colors.homeManagerModule
    sops-nix.homeManagerModules.sops
    paneru.homeModules.paneru
    self.homeManagerModules.neovim
    ../modules/home-manager
    ../applications/atuin
    ../applications/gh-dash
    ../applications/misc
    ../applications/rbw
    ../applications/tmux
  ];
}
