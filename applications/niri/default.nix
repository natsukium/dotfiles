{
  config,
  lib,
  pkgs,
  ...
}:
let
  defaultKeyBind = import ./defaultKeyBind.nix;
  terminal = "felis";
  launcher = [
    "vicinae"
    "toggle"
  ];
in
{
  wayland.windowManager.niri = {
    enable = true;
    # The NixOS module already ships the systemd units and the portal config,
    # so I take only the config file generation from this module.
    systemd.enable = false;
    portalPackage = null;

    settings = {
      binds = defaultKeyBind // {
        "Mod+Return".spawn = terminal;
        "Mod+D".spawn = launcher;
        # mod shift space floating # not support yet https://github.com/YaLTeR/niri/issues/122

        # niri does not deliver Handy's own global hotkey, so drive it via signals.
        # Match by "bin/handy" because the Nix wrapper renames the process to .handy-wrapped.
        "Mod+Space".spawn = [
          "pkill"
          "-USR2"
          "-f"
          "bin/handy"
        ];
        "Mod+Ctrl+Space".spawn = [
          "pkill"
          "-USR1"
          "-f"
          "bin/handy"
        ];
        "Mod+T".spawn = [
          "sh"
          "-c"
          "rbw unlock && rofi-rbw -t password"
        ];
        # The quit action will show a confirmation dialog to avoid accidental exits.
        "Mod+Shift+E" = if config.programs.wlogout.enable then { spawn = "wlogout"; } else { quit = { }; };
      };
      input = {
        focus-follows-mouse = { };
        warp-mouse-to-focus = { };
      };
      xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
      prefer-no-csd = { };
      _children = [
        {
          window-rule = {
            clip-to-geometry = true;
            geometry-corner-radius = 12.0;
          };
        }
      ];
    };
  };
}
