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
    ../../applications/niri
    ../desktop.nix
  ];

  home.packages = with pkgs; [
    rofi-rbw
    wl-clipboard
    wtype
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main.terminal = "kitty";
      main.width = 50;
    };
  };

  programs.wlogout = {
    enable = true;
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = config.gtk.gtk3.extraConfig;
  };

  services.mako = {
    enable = true;
    settings = {
      font = "HackGen35 Console 12";
      width = 300;
      height = 100;
      borderRadius = 5;
      borderSize = 2;
      defaultTimeout = 15000;
    };
    extraConfig = ''
      [mode=do-not-disturb]
      invisible = 1
    '';
  };

  services.wallpaper = {
    enable = true;
    imagePath = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
  };
}
