{ config, ... }:
{
  services.adguardhome = {
    enable = true;
    port = 3333;
    settings = {
      dns = {
        upstream_dns = [
          "[/ts.net/]100.100.100.100"
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
          "https://dns10.quad9.net/dns-query"
        ];
        upstream_mode = "load_balance";
      };
      filtering = {
        rewrites = [
          {
            domain = "*.home.natsukium.com";
            answer = "manyara.tail4108.ts.net";
            enabled = true;
          }
        ];
      };
      filters = [
        {
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          enabled = true;
        }
        {
          name = "Japanese filter";
          url = "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_7_Japanese/filter.txt";
          enabled = true;
        }
      ];
    };
  };

  services.caddy.virtualHosts."http://adguard.home.natsukium.com".extraConfig = ''
    reverse_proxy localhost:${toString config.services.adguardhome.port}
  '';
}
