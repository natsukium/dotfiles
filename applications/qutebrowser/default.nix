{ config, pkgs, ... }:
{
  programs.qutebrowser = {
    enable = true;
    settings = {
      content.blocking.method = "both";
      window.hide_decoration = true;
    };
  };
}
