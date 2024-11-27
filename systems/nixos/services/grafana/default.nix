{ config, pkgs, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
      };
    };
  };
}
