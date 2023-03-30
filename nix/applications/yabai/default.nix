{
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    config = {
      "external_bar" = "all:42:0";
      "top_padding" = 10;
      "bottom_padding" = 10;
      "left_padding" = 10;
      "right_padding" = 10;
      "window_gap" = 10;
      "layout" = "bsp";
      "window_opacity" = "on";
      "window_border" = "on";
      "window_border_blur" = "on";
    };
    extraConfig = ''
      yabai -m rule --add app=CopyQ manage=off
      yabai -m rule --add app=kitty opacity=0.9
    '';
  };
}
