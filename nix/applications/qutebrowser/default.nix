{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs) nixbins;
  bins = nixbins.packages.${pkgs.stdenv.system};
in {
  programs.qutebrowser = {
    enable = true;
    package =
      if pkgs.stdenv.isLinux
      then pkgs.qutebrowser
      else bins.qutebrowser;
    settings = {
      content.blocking.method = "both";
      window.hide_decoration =
        # yabai cannot control qutebrowser with Qt5
        # relate: https://github.com/qutebrowser/qutebrowser/issues/4067
        if (pkgs.stdenv.isLinux)
        then true
        else if (pkgs.lib.versionOlder bins.qutebrowser.version "2.6.0")
        then false
        else true;
    };
  };
}
