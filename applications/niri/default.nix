let
  defaultKeyBind = import ./defaultKeyBind.nix;
  terminal = "kitty";
  launcher = "fuzzel";
in
{
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
    };
    environment = {
      DISPLAY = ":0";
    };
  };
}
