{ lib, pkgs, ... }:

let
  inherit (lib) mkDefault;
in
{
  documentation =
    {
      enable = mkDefault false;
      doc.enable = mkDefault false;
      info.enable = mkDefault false;
      man.enable = mkDefault false;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      nixos.enable = mkDefault false;
    };
}
