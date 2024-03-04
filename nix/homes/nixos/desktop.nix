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

  home.packages = with pkgs; [
    config.nur.repos.natsukium.rofi-rbw
    wl-clipboard
    wtype
  ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main.terminal = "kitty";
      main.width = 50;
    };
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

  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: "Liga HackGen35 Console NF";
        font-size: 12px;
      }
    '';
    settings = {
      mainBar = {
        position = "left";
        width = 30;
        modules-left = [
          "clock"
          "cpu"
          "memory"
        ];
        modules-center = [ "hyprland/window" ];
        modules-right = [ "hyprland/workspaces" ];
        "hyprland/workspaces" = { };
        clock = {
          format = ''
            {:%H:%M
            %b%e}'';
          tooltip = true;
          tooltip-format = "{:%Y.%m.%d %H:%M}";
          interval = 5;
        };
        cpu = {
          interval = 5;
          format = " {usage}%";
          states = {
            warning = 70;
            critical = 90;
          };
        };
        memory = {
          interval = 5;
          format = " {}%";
          states = {
            warning = 70;
            critical = 90;
          };
        };
      };
    };
  };

  services.wallpaper = {
    enable = true;
    imagePath = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
  };
}
