{ ... }:
{
  flake.modules.nixos.blackbox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.blackbox;

      blackboxPort = 9115;

      # Probe each service on its loopback port so a hung-but-running daemon
      # (which the systemd unit alert would miss) still trips ServiceProbeFailed.
      # Ports are read from each service's own config so the list cannot drift.
      # Keyed by service name, which becomes the instance label below: a failing
      # probe should name the service, not a port number nobody memorises.
      probeTargets = {
        grafana = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/api/health";
        prometheus = "http://127.0.0.1:${toString config.services.prometheus.port}/-/healthy";
        loki = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/ready";
        forgejo = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}/";
        miniflux = "http://127.0.0.1:${config.services.miniflux.config.PORT}/healthcheck";
        searx = "http://127.0.0.1:${toString config.services.searx.settings.server.port}/";
        adguardhome = "http://127.0.0.1:${toString config.services.adguardhome.port}/";
        niks3 = "http://${config.services.niks3.httpAddr}/health";
      };
    in
    {
      options.my.services.blackbox.enable =
        mkEnableOption "blackbox HTTP probing of local services, with a probe-failure alert";

      config = mkIf cfg.enable {
        services.prometheus.exporters.blackbox = {
          enable = true;
          port = blackboxPort;
          configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
            modules.http_2xx = {
              prober = "http";
              timeout = "5s";
              http = {
                # Login redirects and auth challenges still prove the service
                # answers HTTP, which is the liveness signal we want.
                valid_status_codes = [
                  200
                  204
                  301
                  302
                  401
                  403
                ];
                follow_redirects = false;
                preferred_ip_protocol = "ip4";
              };
            };
          };
        };

        services.prometheus.scrapeConfigs = [
          {
            job_name = "blackbox";
            metrics_path = "/probe";
            params.module = [ "http_2xx" ];
            static_configs = lib.mapAttrsToList (name: url: {
              labels.instance = name;
              targets = [ url ];
            }) probeTargets;
            # An instance set here survives relabelling, so the probed URL only
            # has to reach __param_target before __address__ is redirected at
            # the exporter. The URL stays visible on the Prometheus targets page.
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${toString blackboxPort}";
              }
            ];
          }
        ];

        services.prometheus.ruleFiles = [
          ((pkgs.formats.yaml { }).generate "blackbox-rules.yaml" {
            groups = [
              {
                name = "blackbox";
                rules = [
                  {
                    alert = "ServiceProbeFailed";
                    expr = "probe_success == 0";
                    for = "5m";
                    labels.severity = "warning";
                    annotations.summary = "HTTP probe failed for {{ $labels.instance }}";
                  }
                ];
              }
            ];
          })
        ];
      };
    };
}
