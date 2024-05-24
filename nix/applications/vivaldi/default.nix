{ config, pkgs, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  programs.chromium = {
    enable = true;
    package = if pkgs.stdenv.isLinux then pkgs.vivaldi else nurpkgs.vivaldi-bin;
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
