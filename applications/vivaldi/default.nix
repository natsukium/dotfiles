{ config, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.vivaldi;
    commandLineArgs = pkgs.lib.optionals config.programs.chromium.enableOzone [
      "--enable-wayland-ime"
    ];
  };

  xdg.configFile."vivaldi/mod.css".text = ''
    #header {
      display: none;
    }

    #titlebar {
      display: none;
    }
  '';
}
