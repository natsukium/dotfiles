{ lib, ... }:
import ../../lib/mkProfile.nix { inherit lib; } {
  name = "server";

  # A server host builds its own docs closure for nothing and never offloads, so
  # both scopes drop documentation and distributed builds. There is no home half:
  # server hosts run no home-manager user.
  system = {
    documentation = {
      enable = lib.mkDefault false;
      doc.enable = lib.mkDefault false;
      info.enable = lib.mkDefault false;
      man.enable = lib.mkDefault false;
    };
    nix.distributedBuilds = false;
  };

  nixos = {
    documentation.nixos.enable = lib.mkDefault false;
    services.caddy.enable = true;
  };
}
