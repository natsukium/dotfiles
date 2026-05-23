{ config, ... }:
{
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets."searxng/env".path;
    settings = {
      server = {
        base_url = "http://search.home.natsukium.com";
        port = 8888;
      };
      # JSON is off by default; hermes-agent's SearXNG backend parses JSON.
      search.formats = [
        "html"
        "json"
      ];
    };
  };

  sops.secrets."searxng/env" = {
    sopsFile = ./secrets.yaml;
    owner = "searx";
  };

  services.caddy.virtualHosts."http://search.home.natsukium.com".extraConfig = ''
    reverse_proxy localhost:${toString config.services.searx.settings.server.port}
  '';
}
