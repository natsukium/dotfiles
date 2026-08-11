{ ... }:
{
  flake.modules.nixos.grafana =
    { config, lib, ... }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.grafana;

      tokenDir = "/run/grafana-renderer";
      tokenFile = "${tokenDir}/token";
      tokenEnvFile = "${tokenDir}/env";
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
                # Every dashboard under ./dashboards refers to this datasource by
                # uid, and until now the uid was whatever Grafana minted on first
                # provisioning. Pinning the value it already holds makes the
                # dependency explicit, so replacing the datasource later cannot
                # silently blank every panel.
                uid = "PBFA97CFB590B2093";
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

        services.grafana-image-renderer = {
          enable = true;
          provisionGrafana = true;
        };

        # provisionGrafana derives the callback from server.http_addr, which is
        # 0.0.0.0 so the dashboard answers on the tailnet; the renderer needs an
        # address it can dial back on, not a bind wildcard.
        services.grafana.settings.rendering.callback_url =
          lib.mkForce "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/";

        # Grafana refuses to start in production mode while renderer_token is
        # still the default, and provisionGrafana does not set one. The token is
        # generated here rather than kept in sops because it never leaves the
        # host: it authenticates one loopback caller to another, and no other
        # machine can use it.
        services.grafana.settings.rendering.renderer_token = "$__file{${tokenFile}}";
        systemd.services.grafana-image-renderer.serviceConfig.EnvironmentFile = tokenEnvFile;

        systemd.services.grafana-renderer-token = {
          description = "Shared token between Grafana and its image renderer";
          requiredBy = [
            "grafana.service"
            "grafana-image-renderer.service"
          ];
          before = [
            "grafana.service"
            "grafana-image-renderer.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            install -d -m 0755 ${tokenDir}
            if [ ! -s ${tokenFile} ]; then
              token=$(head -c 24 /dev/urandom | base32 | tr -d '=')
              printf '%s' "$token" >${tokenFile}
              printf 'AUTH_TOKEN=%s\n' "$token" >${tokenEnvFile}
            fi
            chown root:grafana ${tokenFile}
            chmod 0640 ${tokenFile}
            chmod 0600 ${tokenEnvFile}
          '';
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
