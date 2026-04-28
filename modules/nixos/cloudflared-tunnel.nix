{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.my.services.cloudflared-tunnel;
in
{
  options.my.services.cloudflared-tunnel = {
    enable = mkEnableOption "shared cloudflared tunnel for this host";

    id = mkOption {
      type = types.nonEmptyStr;
      description = ''
        UUID of this host's cloudflared tunnel. Services contribute ingress
        entries to this single tunnel instead of declaring their own — one
        tunnel per host keeps cloudflared to a single process and lets every
        public hostname share the same `<UUID>.cfargotunnel.com` CNAME target.
      '';
    };

    credentialsFile = mkOption {
      type = types.path;
      description = "Path to the cloudflared tunnel credentials JSON.";
    };
  };

  config = mkIf cfg.enable {
    services.cloudflared.tunnels.${cfg.id} = {
      credentialsFile = toString cfg.credentialsFile;
      # explicit 404 fallback so requests for hostnames without an ingress
      # entry fail loudly instead of being routed to whichever service sorts
      # first in the merged attrset
      default = "http_status:404";
    };
  };
}
