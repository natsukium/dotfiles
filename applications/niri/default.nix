{
  inputs,
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
  imports = [ inputs.niri-flake.homeModules.niri ];

  programs.niri.package = pkgs.niri;

  programs.niri.settings = {
    binds = defaultKeyBind // {
      "Mod+Return".action.spawn = terminal;
      "Mod+D".action.spawn = launcher;
      # mod shift space floating # not support yet https://github.com/YaLTeR/niri/issues/122

      # niri does not deliver Handy's own global hotkey, so drive it via signals.
      # Match by "bin/handy" because the Nix wrapper renames the process to .handy-wrapped.
      "Mod+Space".action.spawn = [
        "pkill"
        "-USR2"
        "-f"
        "bin/handy"
      ];
      "Mod+Ctrl+Space".action.spawn = [
        "pkill"
        "-USR1"
        "-f"
        "bin/handy"
      ];
      "Mod+T".action.spawn = [
        "sh"
        "-c"
        "rbw unlock && rofi-rbw -t password"
      ];
      # The quit action will show a confirmation dialog to avoid accidental exits.
      "Mod+Shift+E".action =
        if config.programs.wlogout.enable then { spawn = "wlogout"; } else { quit = { }; };
    };
    input = {
      focus-follows-mouse.enable = true;
      warp-mouse-to-focus.enable = true;
    };
    xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
    prefer-no-csd = true;
    window-rules = [
      {
        clip-to-geometry = true;
        geometry-corner-radius = {
          top-left = 12.0;
          top-right = 12.0;
          bottom-left = 12.0;
          bottom-right = 12.0;
        };
      }
    ];
  };
}
