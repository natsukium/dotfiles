{ config, ... }:
{
  services.adguardhome = {
    enable = true;
    port = 3333;
    settings = {
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
