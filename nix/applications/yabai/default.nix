{ ... }:
{
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    config = {
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 50;
      right_padding = 10;
      window_gap = 10;
      layout = "bsp";
      window_opacity = "on";
      window_animation_duration = 5.0e-2;
      focus_follows_mouse = "autofocus";
      mouse_follows_focus = "on";
    };
    extraConfig = ''
      yabai -m rule --add app=CopyQ manage=off
      yabai -m rule --add app=Pritunl manage=off

      yabai -m rule --add app=kitty opacity=0.9
      yabai -m rule --add label=emacs app=Emacs manage=on
      # https://github.com/qutebrowser/qutebrowser/issues/4067
      yabai -m rule --add app="^qutebrowser$" title!="^$" role="AXWindow" subrole="AXDialog" manage=on
    '';
  };
}
