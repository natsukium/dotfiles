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
          # Exact entries beat the wildcard below, so this steers only hydra to
          # kilimanjaro, where caddy runs next to it; every other
          # *.home.natsukium.com host lives on manyara.
          {
            domain = "hydra.home.natsukium.com";
            answer = "kilimanjaro.tail4108.ts.net";
            enabled = true;
          }
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
