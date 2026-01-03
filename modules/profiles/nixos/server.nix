{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ../../shared/documentation/server.nix
  ];

  documentation.nixos.enable = mkDefault false;

  services.caddy.enable = true;
}
