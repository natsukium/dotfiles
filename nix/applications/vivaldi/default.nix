{ config, pkgs, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  home.packages = if pkgs.stdenv.isLinux then [ pkgs.vivaldi ] else [ nurpkgs.vivaldi-bin ];

  xdg.configFile."vivaldi/mod.css".text = ''
    #header {
      display: none;
    }

    #titlebar {
      display: none;
    }
  '';
}
