{pkgs, ...}: {
  imports = [
    ./common.nix
    ./desktop.nix
    ../applications/sketchybar
  ];
  home.packages = with pkgs; [
    monitorcontrol
  ];
}
