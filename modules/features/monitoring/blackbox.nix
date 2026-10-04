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

      # A hung-but-running daemon passes the systemd unit alert, so probe HTTP
      # instead. Ports come from each service's own config so the list cannot
      # drift; the attr name becomes the instance label so a failing probe
      # names the service, not a port number.
      probeTargets = {
        grafana = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/api/health";
        victoriametrics = "http://127.0.0.1:${toString config.my.services.victoriametrics.port}/-/healthy";
        vmalert = "http://127.0.0.1:${toString config.my.services.victoriametrics.vmalertPort}/-/healthy";
        loki = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/ready";
        forgejo = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}/";
        miniflux = "http://127.0.0.1:${config.services.miniflux.config.PORT}/healthcheck";
        searx = "http://127.0.0.1:${toString config.services.searx.settings.server.port}/";
        adguardhome = "http://127.0.0.1:${toString config.services.adguardhome.port}/";
        niks3 = "http://${config.services.niks3.httpAddr}/health";
      };

      # Each hop along the uplink, so a latency rise can be placed on the LAN,
      # the PPPoE session, the ISP edge, or beyond. The ISP edge address was
      # read off tracepath and moves if the ISP re-routes the session.
      wanTargets = {
        router = "192.168.2.1";
        pppoe = "10.128.0.1";
        isp-edge = "115.31.55.25";
        cloudflare = "1.1.1.1";
        google = "8.8.8.8";
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
                # answers HTTP, which is all a liveness probe needs.
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
            modules.icmp = {
              prober = "icmp";
              timeout = "5s";
              icmp.preferred_ip_protocol = "ip4";
            };
          };
        };

        services.victoriametrics.prometheusConfig.scrape_configs = [
          {
            job_name = "blackbox";
            metrics_path = "/probe";
            params.module = [ "http_2xx" ];
            static_configs = lib.mapAttrsToList (name: url: {
              labels.instance = name;
              targets = [ url ];
            }) probeTargets;
            # The static instance label survives relabelling; the URL moves to
            # __param_target and __address__ is pointed at the exporter.
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
          {
            job_name = "wan";
            metrics_path = "/probe";
            params.module = [ "icmp" ];
            # One echo per probe, so loss is the mean of probe_success and a
            # 1m interval would leave too few samples per hour to read it.
            scrape_interval = "15s";
            static_configs = lib.mapAttrsToList (name: host: {
              labels.instance = name;
              targets = [ host ];
            }) wanTargets;
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

        services.vmalert.instances.main.rules.groups = [
          {
            name = "blackbox";
            rules = [
              {
                alert = "ServiceProbeFailed";
                expr = ''probe_success{job="blackbox"} == 0'';
                for = "5m";
                labels.severity = "warning";
                annotations.summary = "HTTP probe failed for {{ $labels.instance }}";
              }
            ];
          }
        ];
      };
    };
}
