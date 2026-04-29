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
        UUID of this host's cloudflared tunnel. Kept as host-local config so
        services contributing ingress entries do not need to know it: they
        write to `my.services.cloudflared-tunnel.ingress`, and this module
        funnels the result into `services.cloudflared.tunnels.<id>`.
      '';
    };

    credentialsFile = mkOption {
      type = types.path;
      description = "Path to the cloudflared tunnel credentials JSON.";
    };

    ingress = mkOption {
      type = types.attrsOf (types.either types.str types.attrs);
      default = { };
      example = {
        "git.example.com".service = "http://localhost:3010";
      };
      description = ''
        Hostnames to expose through this host's shared tunnel. Merged into
        `services.cloudflared.tunnels.<id>.ingress`, so the value shape is
        whatever the upstream module accepts (a service URL string, or a
        submodule with `service` / `path` / `originRequest`). Lets per-service
        modules declare their public hostname without referencing the tunnel
        UUID.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.cloudflared.tunnels.${cfg.id} = {
      credentialsFile = toString cfg.credentialsFile;
      ingress = cfg.ingress;
      # explicit 404 fallback so requests for hostnames without an ingress
      # entry fail loudly instead of being routed to whichever service sorts
      # first in the merged attrset
      default = "http_status:404";
    };
  };
}
