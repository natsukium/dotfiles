{ config, ... }:
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      PORT = "8080";
    };
  };

  services.tsnsrv.services.rss-reader = {
    ephemeral = true;
    authKeyPath = config.sops.secrets.tailscale-authkey.path;
    toURL = "http://127.0.0.1:${config.services.miniflux.config.PORT}";
  };

  sops.secrets.miniflux = { };
}
