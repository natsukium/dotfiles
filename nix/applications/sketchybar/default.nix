{ pkgs, ... }:
let
  sketchybarrc-py = pkgs.python3Packages.callPackage ../../pkgs/sketchybarrc-py { };
  flakeIgnore = [
    "E402"
    "W503"
    "E501"
  ];
  libraries = with pkgs.python3Packages; [
    typing-extensions
    sketchybarrc-py
  ];

  rc = pkgs.writers.writePython3Bin "sketchybarrc" { inherit flakeIgnore libraries; } (
    builtins.readFile ./sketchybarrc.py
  );
  battery = pkgs.writers.writePython3Bin "battery.py" { inherit flakeIgnore libraries; } (
    builtins.readFile ./plugins/battery.py
  );
  clock = pkgs.writers.writePython3Bin "clock.py" { inherit flakeIgnore libraries; } (
    builtins.readFile ./plugins/clock.py
  );
  weather = pkgs.writers.writePython3Bin "weather.py" { inherit flakeIgnore libraries; } (
    builtins.readFile ./plugins/weather.py
  );
in
{
  xdg.configFile."sketchybar/sketchybarrc".source = "${rc}/bin/sketchybarrc";
  xdg.configFile."sketchybar/plugins/battery.py".source = "${battery}/bin/battery.py";
  xdg.configFile."sketchybar/plugins/clock.py".source = "${clock}/bin/clock.py";
  xdg.configFile."sketchybar/plugins/weather.py".source = "${weather}/bin/weather.py";
}
