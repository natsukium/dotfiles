{
  pkgs,
  inputs,
  config,
  ...
}:
let
  wallpaper = pkgs.callPackage ../../pkgs/wallpaper {
    wallpaper = inputs.nix-wallpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;
    inherit (config.colorScheme) palette;
  };
in
{
  imports = [
    ../../applications/hyprland
    ../desktop.nix
  ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc ];
  };

  home.packages = [ pkgs.wofi ];

  services.mako = {
    enable = true;
    font = "HackGen35 Console 12";
    width = 300;
    height = 100;
    borderRadius = 5;
    borderSize = 2;
    defaultTimeout = 15000;
    extraConfig = ''
      [mode=do-not-disturb]
      invisible=1
    '';
  };

  services.wallpaper = {
    enable = true;
    imagePath = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
  };
}
