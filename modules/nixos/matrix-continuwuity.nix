{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.my.services.matrix-continuwuity;
  tunnelId = config.my.services.cloudflared-tunnel.id;
  port = lib.head config.services.matrix-continuwuity.settings.global.port;
in
{
  options.my.services.matrix-continuwuity = {
    enable = mkEnableOption "Continuwuity Matrix homeserver behind a cloudflared tunnel";

    serverName = mkOption {
      type = types.nonEmptyStr;
      example = "example.com";
      description = ''
        Matrix `server_name`: used as the user/room ID suffix and as the
        canonical federation identity. When this differs from `apiHost`,
        federation discovery for `serverName` must be delegated to `apiHost`
        externally (e.g. by serving `/.well-known/matrix/server` from the
        `serverName` apex via a separate Worker / static host).
      '';
    };

    apiHost = mkOption {
      type = types.nonEmptyStr;
      default = cfg.serverName;
      defaultText = lib.literalExpression "config.my.services.matrix-continuwuity.serverName";
      example = "matrix.example.com";
      description = ''
        Hostname the actual Continuwuity HTTP server is reachable at -- the
        cloudflared tunnel ingress points here, and continuwuity's own
        `well_known` advertises this as the API endpoint. Defaults to
        `serverName` (no delegation), set to a subdomain when running the
        homeserver under a delegated apex.
      '';
    };

    enableFederation = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether the homeserver federates with the wider Matrix network.
        Off by default so the instance can be run closed while moderation
        policy (server blocklists, abuse contact, etc.) is being decided;
        flipping to true exposes inbound federation endpoints and lets local
        users join rooms on other servers.
      '';
    };

    environmentFile = mkOption {
      type = types.path;
      description = ''
        systemd-style env file consumed by the continuwuity unit. Continuwuity
        treats `CONTINUWUITY_*` / `CONDUWUIT_*` env vars as global config
        overrides, so the registration token is supplied as
        `CONTINUWUITY_REGISTRATION_TOKEN=<value>` here rather than via the
        `registration_token` TOML key (which would land in the world-readable
        Nix store) or via an ExecStart wrapper using `$(cat ...)` (which the
        upstream unit's hardened sandbox -- PrivateIPC, RemoveIPC, syscall
        filter dropping @ipc -- blocks).
      '';
    };
  };

  config = mkIf cfg.enable {
    services.matrix-continuwuity = {
      enable = true;
      settings.global = {
        server_name = cfg.serverName;
        allow_federation = cfg.enableFederation;
        # token-gated instead of fully closed so new accounts can be created
        # without redeploying; set to false to fully lock the server down.
        # The token value itself is injected via env var (see environmentFile).
        allow_registration = true;
        # cloudflared only exposes 443, so delegate federation and client
        # discovery there instead of the default 8448. apiHost rather than
        # serverName: when serverName is an apex with no homeserver bound,
        # the actual API lives on a subdomain that the apex's external
        # well-known points at.
        well_known = {
          server = "${cfg.apiHost}:443";
          client = "https://${cfg.apiHost}";
        };
      };
    };

    systemd.services.continuwuity.serviceConfig.EnvironmentFile = cfg.environmentFile;

    services.cloudflared.tunnels.${tunnelId}.ingress."${cfg.apiHost}" = {
      service = "http://localhost:${toString port}";
    };
  };
}
