{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.ext.security;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options = {
    ext.security.secureboot = {
      enable = mkEnableOption "Enable secure boot with lanzaboote";
    };
  };

  config = mkIf cfg.secureboot.enable {

    environment.systemPackages = mkIf cfg.secureboot.enable [
      pkgs.sbctl
    ];

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    boot.loader.systemd-boot.enable = false;
  };
}
