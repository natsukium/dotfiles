{ config, ... }:
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      PORT = "8080";
    };
  };

  services.caddy.virtualHosts."http://rss.home.natsukium.com".extraConfig = ''
    reverse_proxy localhost:${config.services.miniflux.config.PORT}
  '';

  sops.secrets.miniflux = { };
}
