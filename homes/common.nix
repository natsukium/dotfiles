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
    ;
in
{
  programs.home-manager.enable = true;
  home = {
    stateVersion = "24.11";
  };

  home.preferXdgDirectories = true;

  my.services.org-sync = {
    enable = true;
    devices.manyara.id = "QR5JSZF-GGDDSEQ-5LEDB4S-RGLWILH-OYVRYII-GUCDB3V-W3TNVAX-QTCZEAB";
  };

  colorScheme = nix-colors.colorSchemes.nord;
  base16.enable = true;

  my.programs.neovim.enable = true;

  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  imports = [
    nix-colors.homeManagerModule
    sops-nix.homeManagerModules.sops
    paneru.homeModules.paneru
    ../modules/home-manager
    ../modules/home/org-sync
    ../applications/atuin
    ../applications/gh-dash
    ../applications/misc
    ../applications/rbw
    ../applications/tmux
  ];
}
