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
  imports = [
    ../../applications/hammerspoon
    ../../applications/jankyborders
    ../../applications/sketchybar
    ../desktop.nix
    ./gui-apps-utils
  ];

  home.packages = with pkgs; [
    monitorcontrol
    nowplaying-cli
    zen-browser
  ];

  services.raycast.enable = true;

  services.wallpaper = {
    enable = true;
    imagePath = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
  };
}
