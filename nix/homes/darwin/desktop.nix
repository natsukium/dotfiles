{
  inputs,
  pkgs,
  config,
  ...
}:
let
  nurpkgs = config.nur.repos.natsukium;
  wallpaper = pkgs.callPackage ../../pkgs/wallpaper {
    wallpaper = inputs.nix-wallpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;
    inherit (config.colorScheme) colors;
    width = 2560;
    height = 1600;
  };
in
{
  imports = [
    ../../applications/sketchybar
    ../desktop.nix
  ];

  home.packages = with pkgs; [
    monitorcontrol
    nurpkgs.nowplaying-cli
    raycast
  ];

  services.wallpaper = {
    enable = true;
    imagePath = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
  };
}
