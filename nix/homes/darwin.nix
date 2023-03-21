{pkgs, ...}: {
  imports = [
    ./common.nix
    ./desktop.nix
    ../applications/sketchybar
  ];
}
