{ config, pkgs, ... }:
{
  programs.qutebrowser = {
    enable = true;
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
