{ config, pkgs, ... }:
{
  programs.alacritty = {
    enable = false;
  };

  xdg.configFile = pkgs.lib.optionalAttrs config.programs.alacritty.enable {
    "alacritty/alacritty.yml".source = ./alacritty.yml;
  };
}
