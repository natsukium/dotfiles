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
    authKeyPath = "/run/credentials/tsnsrv-rss-reader.service/credentials";
    toURL = "http://127.0.0.1:${config.services.miniflux.config.PORT}";
  };

  sops.secrets.miniflux = { };
}
