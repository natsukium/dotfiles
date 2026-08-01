{
  # Neither niri nor the home-manager module ships niri's default binds, so they
  # are vendored here from upstream's default-config.kdl.
  # Keys consist of modifiers separated by + signs, followed by an XKB key name
  # in the end. To find an XKB name for a particular key, you may use a program
  # like wev.
  #
  # "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
  # when running as a winit window.
  #
  # Most actions that you can bind here can also be invoked programmatically with
  # `niri msg action do-something`.

  # Mod-Shift-/, which is usually the same as Mod-?,
  # shows a list of important hotkeys.
  "Mod+Shift+Slash".show-hotkey-overlay = { };

  # Suggested binds for running programs: terminal, app launcher, screen locker.
  "Mod+T".spawn = "alacritty";
  "Mod+D".spawn = "fuzzel";
  "Super+Alt+L".spawn = "swaylock";

  # You can also use a shell. Do this if you need pipes, multiple commands, etc.
  # Note: the entire command goes as a single argument in the end.
  # Mod+T { spawn "bash" "-c" "notify-send hello && exec alacritty"; }

  # Example volume keys mappings for PipeWire & WirePlumber.
  # The allow-when-locked=true property makes them work even when the session is locked.
  "XF86AudioRaiseVolume" = {
    _props.allow-when-locked = true;
    spawn = [
      "wpctl"
      "set-volume"
      "@DEFAULT_AUDIO_SINK@"
      "0.1+"
    ];
  };
  "XF86AudioLowerVolume" = {
    _props.allow-when-locked = true;
    spawn = [
      "wpctl"
      "set-volume"
      "@DEFAULT_AUDIO_SINK@"
      "0.1-"
    ];
  };
  "XF86AudioMute" = {
    _props.allow-when-locked = true;
    spawn = [
      "wpctl"
      "set-mute"
      "@DEFAULT_AUDIO_SINK@"
      "toggle"
    ];
  };
  "XF86AudioMicMute" = {
    _props.allow-when-locked = true;
    spawn = [
      "wpctl"
      "set-mute"
      "@DEFAULT_AUDIO_SOURCE@"
      "toggle"
    ];
  };

  "Mod+Q".close-window = { };

  "Mod+Left".focus-column-left = { };
  "Mod+Down".focus-window-down = { };
  "Mod+Up".focus-window-up = { };
  "Mod+Right".focus-column-right = { };
  "Mod+H".focus-column-left = { };
  "Mod+J".focus-window-down = { };
  "Mod+K".focus-window-up = { };
  "Mod+L".focus-column-right = { };

  "Mod+Ctrl+Left".move-column-left = { };
  "Mod+Ctrl+Down".move-window-down = { };
  "Mod+Ctrl+Up".move-window-up = { };
  "Mod+Ctrl+Right".move-column-right = { };
  "Mod+Ctrl+H".move-column-left = { };
  "Mod+Ctrl+J".move-window-down = { };
  "Mod+Ctrl+K".move-window-up = { };
  "Mod+Ctrl+L".move-column-right = { };

  # Alternative commands that move across workspaces when reaching
  # the first or last window in a column.
  # Mod+J     { focus-window-or-workspace-down; }
  # Mod+K     { focus-window-or-workspace-up; }
  # Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
  # Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

  "Mod+Home".focus-column-first = { };
  "Mod+End".focus-column-last = { };
  "Mod+Ctrl+Home".move-column-to-first = { };
  "Mod+Ctrl+End".move-column-to-last = { };

  "Mod+Shift+Left".focus-monitor-left = { };
  "Mod+Shift+Down".focus-monitor-down = { };
  "Mod+Shift+Up".focus-monitor-up = { };
  "Mod+Shift+Right".focus-monitor-right = { };
  "Mod+Shift+H".focus-monitor-left = { };
  "Mod+Shift+J".focus-monitor-down = { };
  "Mod+Shift+K".focus-monitor-up = { };
  "Mod+Shift+L".focus-monitor-right = { };

  "Mod+Shift+Ctrl+Left".move-column-to-monitor-left = { };
  "Mod+Shift+Ctrl+Down".move-column-to-monitor-down = { };
  "Mod+Shift+Ctrl+Up".move-column-to-monitor-up = { };
  "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = { };
  "Mod+Shift+Ctrl+H".move-column-to-monitor-left = { };
  "Mod+Shift+Ctrl+J".move-column-to-monitor-down = { };
  "Mod+Shift+Ctrl+K".move-column-to-monitor-up = { };
  "Mod+Shift+Ctrl+L".move-column-to-monitor-right = { };

  # Alternatively, there are commands to move just a single window:
  # Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
  # ...

  # And you can also move a whole workspace to another monitor:
  # Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
  # ...

  "Mod+Page_Down".focus-workspace-down = { };
  "Mod+Page_Up".focus-workspace-up = { };
  "Mod+U".focus-workspace-down = { };
  "Mod+I".focus-workspace-up = { };
  "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
  "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };
  "Mod+Ctrl+U".move-column-to-workspace-down = { };
  "Mod+Ctrl+I".move-column-to-workspace-up = { };

  # Alternatively, there are commands to move just a single window:
  # Mod+Ctrl+Page_Down { move-window-to-workspace-down; }
  # ...

  "Mod+Shift+Page_Down".move-workspace-down = { };
  "Mod+Shift+Page_Up".move-workspace-up = { };
  "Mod+Shift+U".move-workspace-down = { };
  "Mod+Shift+I".move-workspace-up = { };

  # You can bind mouse wheel scroll ticks using the following syntax.
  # These binds will change direction based on the natural-scroll setting.
  #
  # To avoid scrolling through workspaces really fast, you can use
  # the cooldown-ms property. The bind will be rate-limited to this value.
  # You can set a cooldown on any bind, but it's most useful for the wheel.
  "Mod+WheelScrollDown" = {
    _props.cooldown-ms = 150;
    focus-workspace-down = { };
  };
  "Mod+WheelScrollUp" = {
    _props.cooldown-ms = 150;
    focus-workspace-up = { };
  };
  "Mod+Ctrl+WheelScrollDown" = {
    _props.cooldown-ms = 150;
    move-column-to-workspace-down = { };
  };
  "Mod+Ctrl+WheelScrollUp" = {
    _props.cooldown-ms = 150;
    move-column-to-workspace-up = { };
  };

  "Mod+WheelScrollRight".focus-column-right = { };
  "Mod+WheelScrollLeft".focus-column-left = { };
  "Mod+Ctrl+WheelScrollRight".move-column-right = { };
  "Mod+Ctrl+WheelScrollLeft".move-column-left = { };

  # Usually scrolling up and down with Shift in applications results in
  # horizontal scrolling; these binds replicate that.
  "Mod+Shift+WheelScrollDown".focus-column-right = { };
  "Mod+Shift+WheelScrollUp".focus-column-left = { };
  "Mod+Ctrl+Shift+WheelScrollDown".move-column-right = { };
  "Mod+Ctrl+Shift+WheelScrollUp".move-column-left = { };

  # Similarly, you can bind touchpad scroll "ticks".
  # Touchpad scrolling is continuous, so for these binds it is split into
  # discrete intervals.
  # These binds are also affected by touchpad's natural-scroll, so these
  # example binds are "inverted", since we have natural-scroll enabled for
  # touchpads by default.
  # Mod+TouchpadScrollDown { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02+"; }
  # Mod+TouchpadScrollUp   { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02-"; }

  # You can refer to workspaces by index. However, keep in mind that
  # niri is a dynamic workspace system, so these commands are kind of
  # "best effort". Trying to refer to a workspace index bigger than
  # the current workspace count will instead refer to the bottommost
  # (empty) workspace.
  #
  # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
  # will all refer to the 3rd workspace.
  "Mod+1".focus-workspace = 1;
  "Mod+2".focus-workspace = 2;
  "Mod+3".focus-workspace = 3;
  "Mod+4".focus-workspace = 4;
  "Mod+5".focus-workspace = 5;
  "Mod+6".focus-workspace = 6;
  "Mod+7".focus-workspace = 7;
  "Mod+8".focus-workspace = 8;
  "Mod+9".focus-workspace = 9;
  "Mod+Ctrl+1".move-column-to-workspace = 1;
  "Mod+Ctrl+2".move-column-to-workspace = 2;
  "Mod+Ctrl+3".move-column-to-workspace = 3;
  "Mod+Ctrl+4".move-column-to-workspace = 4;
  "Mod+Ctrl+5".move-column-to-workspace = 5;
  "Mod+Ctrl+6".move-column-to-workspace = 6;
  "Mod+Ctrl+7".move-column-to-workspace = 7;
  "Mod+Ctrl+8".move-column-to-workspace = 8;
  "Mod+Ctrl+9".move-column-to-workspace = 9;

  # Alternatively, there are commands to move just a single window:
  # Mod+Ctrl+1 { move-window-to-workspace 1; }

  # Switches focus between the current and the previous workspace.
  # Mod+Tab { focus-workspace-previous; }

  "Mod+Comma".consume-window-into-column = { };
  "Mod+Period".expel-window-from-column = { };

  # There are also commands that consume or expel a single window to the side.
  # Mod+BracketLeft  { consume-or-expel-window-left; }
  # Mod+BracketRight { consume-or-expel-window-right; }

  "Mod+R".switch-preset-column-width = { };
  "Mod+Shift+R".reset-window-height = { };
  "Mod+F".maximize-column = { };
  "Mod+Shift+F".fullscreen-window = { };
  "Mod+C".center-column = { };

  # Finer width adjustments.
  # This command can also:
  # * set width in pixels: "1000"
  # * adjust width in pixels: "-5" or "+5"
  # * set width as a percentage of screen width: "25%"
  # * adjust width as a percentage of screen width: "-10%" or "+10%"
  # Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
  # set-column-width "100" will make the column occupy 200 physical screen pixels.
  "Mod+Minus".set-column-width = "-10%";
  "Mod+Equal".set-column-width = "+10%";

  # Finer height adjustments when in column with other windows.
  "Mod+Shift+Minus".set-window-height = "-10%";
  "Mod+Shift+Equal".set-window-height = "+10%";

  # Actions to switch layouts.
  # Note: if you uncomment these, make sure you do NOT have
  # a matching layout switch hotkey configured in xkb options above.
  # Having both at once on the same hotkey will break the switching,
  # since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
  # Mod+Space       { switch-layout "next"; }
  # Mod+Shift+Space { switch-layout "prev"; }

  "Print".screenshot = { };
  "Ctrl+Print".screenshot-screen = { };
  "Alt+Print".screenshot-window = { };

  # Powers off the monitors. To turn them back on, do any input like
  # moving the mouse or pressing any other key.
  "Mod+Shift+P".power-off-monitors = { };
}
