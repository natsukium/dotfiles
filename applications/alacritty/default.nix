{ config, pkgs, ... }:
{
  programs.alacritty = {
    enable = false;
    settings = {
      window = {
        padding = {
          x = 5;
          y = 5;
        };
        decorations = "None";
        opacity = 0.9;
      };
      font = {
        normal = {
          family = "HackGenNerd Console";
          style = "Regular";
        };
        size = 12;
      };
      bell = {
        animation = "EaseOutExpo";
      };
      selection = {
        save_to_clipboard = true;
      };
    };
  };
}
