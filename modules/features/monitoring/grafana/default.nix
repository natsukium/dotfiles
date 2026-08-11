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
            # Provisioning matches by name, so a rename is an insert that
            # collides on the uid the old row still holds; the old name has to
            # be retired in the same pass.
            datasources.settings.deleteDatasources = [
              {
                name = "Prometheus";
                orgId = 1;
              }
            ];
            datasources.settings.datasources = [
              {
                name = "VictoriaMetrics";
                # VictoriaMetrics answers the Prometheus query API, so the
                # stock Prometheus datasource drives it and the type recorded
                # in every dashboard panel stays valid.
                type = "prometheus";
                # The uid Grafana originally minted; every dashboard under
                # ./dashboards refers to it, so changing it would orphan every
                # panel.
                uid = "PBFA97CFB590B2093";
                url = "http://127.0.0.1:${toString config.my.services.victoriametrics.port}/prometheus";
                isDefault = true;
                # $__rate_interval is derived from this. Left unset Grafana
                # assumes 15s and computes rate windows shorter than the 1m
                # scrape, which reads as gaps in every rate panel.
                jsonData.timeInterval = "1m";
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

        # Grafana refuses production mode while renderer_token is the default,
        # and provisionGrafana sets none. Generated on the host rather than in
        # sops because it only authenticates one loopback caller to another.
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
