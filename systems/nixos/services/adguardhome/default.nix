{ config, ... }:
{
  services.adguardhome = {
    enable = true;
    port = 3333;
    settings = {
      dns = {
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
          "https://dns10.quad9.net/dns-query"
        ];
        upstream_mode = "load_balance";
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
}
