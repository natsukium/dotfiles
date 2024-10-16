{ config, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    # use snapshot to enable text-input-version 3 support
    package =
      if pkgs.stdenv.hostPlatform.isLinux then
        (pkgs.vivaldi.override { isSnapshot = true; }).overrideAttrs (oldAttrs: {
          version = "6.10.3491.4";
          src = pkgs.fetchurl {
            url = "https://downloads.vivaldi.com/snapshot/vivaldi-snapshot_6.10.3491.4-1_amd64.deb";
            hash = "sha256-jbDLdcyjwrsvmSM1MbPSeGMtcewiSDDKzN4nVYo/V/U=";
          };
        })
      else
        pkgs.vivaldi;
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
