{
  inputs,
  pkgs,
  config,
  ...
}:
let
  wallpaper = pkgs.callPackage ../../pkgs/wallpaper {
    wallpaper = inputs.nix-wallpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;
    inherit (config.colorScheme) palette;
    width = 2560;
    height = 1600;
  };
in
{
  imports = [ ../desktop.nix ];

  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };

  my.programs.paneru.enable = true;

  home.packages = with pkgs; [
    monitorcontrol
    nowplaying-cli
  ];

  services.wallpaper = {
    enable = true;
    imagePath = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
  };

  my.services.skhd.enable = true;
}
