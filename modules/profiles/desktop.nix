{ lib, ... }:
import ../../lib/mkProfile.nix { inherit lib; } {
  name = "desktop";

  nixos = {
    my.services.tailscale.configureResolver = lib.mkDefault true;
    # Add the user to the input group so Handy can read the global hotkey from
    # /dev/input/event*; the home half installs and autostarts it on both platforms.
    my.programs.handy.enable = lib.mkDefault true;
  };

  home = {
    my.programs.zen-browser.enable = lib.mkDefault true;
    my.programs.handy.enable = lib.mkDefault true;
  };
}
