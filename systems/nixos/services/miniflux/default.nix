{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Miniflux deduplicates per feed only: the uniqueness key is (feed_id, hash),
  # so an article syndicated by two feeds is stored twice by design, and
  # cross-feed deduplication has sat unimplemented upstream since 2020
  # (miniflux/v2#797). Filter rules cannot express it either -- they match one
  # entry against a regex, never against other entries -- so reconcile after
  # the fact through the API.
  dedup = pkgs.callPackage ../../../../pkgs/miniflux-dedup { };
in
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      PORT = "8080";
    };
  };

  # The credentials file miniflux already consumes doubles as the API login:
  # the API accepts HTTP Basic auth, so reusing it saves provisioning a
  # per-application key by hand and keeping a second secret in sync.
  systemd.services.miniflux-dedup = {
    description = "Mark cross-feed duplicate Miniflux entries as read";
    after = [ "miniflux.service" ];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      ExecStart = lib.getExe dedup;
      EnvironmentFile = config.sops.secrets.miniflux.path;
      # Reach miniflux on the loopback port rather than through Caddy, which
      # keeps the sweep off the TLS path it has no reason to exercise, and
      # keeps the port declared once here.
      Environment = "MINIFLUX_URL=http://localhost:${config.services.miniflux.config.PORT}";
    };
  };
  systemd.timers.miniflux-dedup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "1h";
    };
  };

  services.caddy.virtualHosts."http://rss.home.natsukium.com".extraConfig = ''
    reverse_proxy localhost:${config.services.miniflux.config.PORT}
  '';

  sops.secrets.miniflux = { };
}
