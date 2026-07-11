{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ../documentation-server.nix
  ];

  documentation.nixos.enable = mkDefault false;

  nix.distributedBuilds = false;

  services.caddy.enable = true;
}
