{ config, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.vivaldi;
    enableOzone = pkgs.stdenv.hostPlatform.isLinux;
    commandLineArgs = pkgs.lib.optionals config.programs.chromium.enableOzone [
      "--enable-wayland-ime"
      "--wayland-text-input-version=3"
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
