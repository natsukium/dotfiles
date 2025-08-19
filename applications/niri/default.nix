{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  defaultKeyBind = import ./defaultKeyBind.nix;
  terminal = "kitty";
  launcher = "fuzzel";
in
{
  imports = [ inputs.niri-flake.homeModules.niri ];

  programs.niri.package = pkgs.niri;

  programs.niri.settings = {
    binds = defaultKeyBind // {
      "Mod+Return".action.spawn = terminal;
      "Mod+D".action.spawn = launcher;
      # mod shift space floating # not support yet https://github.com/YaLTeR/niri/issues/122
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
    # XWayland
    spawn-at-startup = [
      { command = [ "${lib.getExe pkgs.xwayland-satellite}" ]; }
    ];
    environment = {
      DISPLAY = ":0";
    };
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
