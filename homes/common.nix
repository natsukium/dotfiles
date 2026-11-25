{
  inputs,
  ...
}:
let
  inherit (inputs)
    nix-colors
    nix-mac-app-identity
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

  imports = [
    nix-colors.homeManagerModule
    sops-nix.homeManagerModules.sops
    paneru.homeModules.paneru
    nix-mac-app-identity.homeManagerModules.default
  ];
}
