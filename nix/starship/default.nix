{ pkgs, ... }:

{
  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = ./starship.toml;
}
