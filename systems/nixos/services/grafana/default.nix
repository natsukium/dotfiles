{ config, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3001;
        enable_gzip = true;
      };
      security.secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
        }
      ];
    };
  };

  sops.secrets.grafana-secret-key = {
    sopsFile = ./secrets.yaml;
    owner = "grafana";
  };
}
