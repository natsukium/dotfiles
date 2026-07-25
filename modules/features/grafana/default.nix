{ ... }:
{
  flake.modules.nixos.grafana =
    { config, lib, ... }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.grafana;
    in
    {
      options.my.services.grafana.enable =
        mkEnableOption "Grafana with provisioned datasources and dashboards";

      config = mkIf cfg.enable {
        services.grafana = {
          enable = true;
          settings = {
            server = {
              http_addr = "0.0.0.0";
              http_port = 3001;
              enable_gzip = true;
              domain = "monitor.home.natsukium.com";
              root_url = "http://monitor.home.natsukium.com/";
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
              {
                name = "Loki";
                type = "loki";
                uid = "loki";
                url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                # Claude Code events carry a trace_id in structured metadata;
                # turn it into a clickable link into Tempo so a log jumps to its
                # trace (the reverse of Tempo's tracesToLogsV2 below).
                jsonData.derivedFields = [
                  {
                    name = "trace_id";
                    matcherType = "label";
                    matcherRegex = "trace_id";
                    datasourceUid = "tempo";
                    url = "\${__value.raw}";
                    urlDisplayLabel = "View trace";
                  }
                ];
              }
              {
                name = "Tempo";
                type = "tempo";
                uid = "tempo";
                url = "http://127.0.0.1:${toString config.services.tempo.settings.server.http_listen_port}";
                # Jump from a trace span to the matching Claude Code events in
                # Loki. filterByTraceID narrows to the span's trace so the log
                # panel is not flooded with the whole time range.
                jsonData.tracesToLogsV2 = {
                  datasourceUid = "loki";
                  spanStartTimeShift = "-1h";
                  spanEndTimeShift = "1h";
                  filterByTraceID = true;
                };
              }
            ];
            dashboards.settings = {
              apiVersion = 1;
              providers = [
                {
                  name = "nix-managed";
                  options.path = "${./dashboards}";
                  options.foldersFromFilesStructure = true;
                  allowUiUpdates = false;
                  disableDeletion = true;
                }
              ];
            };
          };
        };

        services.caddy.virtualHosts."http://${config.services.grafana.settings.server.domain}".extraConfig =
          ''
            reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
          '';

        sops.secrets.grafana-secret-key = {
          sopsFile = ./secrets.yaml;
          owner = "grafana";
        };
      };
    };
}
