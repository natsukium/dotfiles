{ config, pkgs, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  programs.qutebrowser = {
    enable = true;
    package = if pkgs.stdenv.isLinux then pkgs.qutebrowser else nurpkgs.qutebrowser;
    settings = {
      content.blocking.method = "both";
      window.hide_decoration =
        # yabai cannot control qutebrowser with Qt5
        # relate: https://github.com/qutebrowser/qutebrowser/issues/4067
        if (pkgs.stdenv.isLinux) then
          true
        else if (pkgs.lib.versionOlder config.programs.qutebrowser.package.version "2.6.0") then
          false
        else
          true;
    };
  };
}
