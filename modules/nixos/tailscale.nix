# This file is auto-generated from configuration.org.
# Do not edit directly.

{ config, lib, ... }:
let
  cfg = config.my.services.tailscale;
in
{
  options.my.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";

    configureResolver = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable systemd-resolved for Tailscale DNS.
        Recommended for desktop systems to mitigate DNS failures after suspend/resume.
        https://github.com/tailscale/tailscale/issues/4254
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "server";
          authKeyFile = config.sops.secrets.tailscale-authkey.path;
          extraUpFlags = [ "--ssh" ];
        };

        networking = {
          firewall = {
            trustedInterfaces = [ "tailscale0" ];
            allowedUDPPorts = [ config.services.tailscale.port ];
          };
          nameservers = [
            "100.100.100.100"
            "8.8.8.8"
          ];
          search = [ "tail4108.ts.net" ];
        };

        sops.secrets.tailscale-authkey = { };
      }
      (lib.mkIf cfg.configureResolver {
        services.resolved.enable = cfg.configureResolver;
      })
    ]
  );
}
