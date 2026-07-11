{ lib, ... }:
import ../../lib/mkProfile.nix { inherit lib; } {
  name = "desktop";

  nixos = {
    my.services.tailscale.configureResolver = lib.mkDefault true;
  };

  home = {
    my.programs.zen-browser.enable = lib.mkDefault true;
  };
}
