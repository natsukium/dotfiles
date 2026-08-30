{ lib, ... }:
let
  # Receives OTLP from Claude Code on localhost and fans it out to manyara:
  # remote_write to VictoriaMetrics, OTLP to Loki and Tempo. Sessions are too
  # short-lived to scrape, so metrics are pushed like the logs. One body for
  # both platforms since Alloy runs on both via my.services.alloy.
  module =
    { config, inputs, ... }:
    let
      cfg = config.my.services.otel-collector;

      hostname = config.networking.hostName;
      manyara = inputs.self.outputs.nixosConfigurations.manyara.config;
      # Full tailnet FQDN, matching modules/features/comin/alloy.nix: the short
      # name resolves inconsistently across Linux and macOS resolvers.
      host = "manyara.tail4108.ts.net";
      metricsEndpoint = "http://${host}:${toString manyara.my.services.victoriametrics.port}/api/v1/write";
      # Loki's OTLP ingest promotes service.name to a service_name label by
      # default, so events are queryable without hint plumbing.
      lokiEndpoint = "http://${host}:${toString manyara.services.loki.configuration.server.http_listen_port}/otlp";
      # Standard OTLP/gRPC port, matching the receiver in ./tempo.nix.
      tempoEndpoint = "${host}:4317";
    in
    {
      options.my.services.otel-collector.enable =
        lib.mkEnableOption "Alloy OTLP receiver for Claude Code telemetry";

      config = lib.mkIf cfg.enable {
        my.services.alloy.configs.otlp = ''
          otelcol.receiver.otlp "claude_code" {
            grpc {
              endpoint = "127.0.0.1:4317"
            }

            http {
              endpoint = "127.0.0.1:4318"
            }

            output {
              metrics = [otelcol.exporter.prometheus.claude_code.input]
              logs    = [otelcol.processor.transform.host.input]
              traces  = [otelcol.processor.transform.host.input]
            }
          }

          // Only the metrics path picks up a hostname, from remote_write's
          // external_labels below. Stamp the same name onto logs and traces so
          // one dashboard variable can filter all three signals.
          otelcol.processor.transform "host" {
            error_mode = "ignore"

            log_statements {
              context    = "resource"
              statements = [`set(attributes["host.name"], "${hostname}")`]
            }

            trace_statements {
              context    = "resource"
              statements = [`set(attributes["host.name"], "${hostname}")`]
            }

            output {
              logs   = [otelcol.exporter.otlphttp.loki.input]
              traces = [otelcol.exporter.otlp.claude_code.input]
            }
          }

          otelcol.exporter.prometheus "claude_code" {
            // Drop the unit and _total suffixes so metric names keep the
            // predictable claude_code_* form the dashboard queries against.
            add_metric_suffixes = false
            forward_to          = [prometheus.remote_write.manyara.receiver]
          }

          // Alloy names this component after the protocol, not the server;
          // VictoriaMetrics accepts remote_write on the same path.
          prometheus.remote_write "manyara" {
            // Claude Code metrics carry no host identity of their own; tag them
            // here so the fleet's sessions are distinguishable in Grafana.
            external_labels = {
              host = "${hostname}",
            }

            endpoint {
              url = "${metricsEndpoint}"
            }
          }

          otelcol.exporter.otlphttp "loki" {
            client {
              endpoint = "${lokiEndpoint}"
            }
          }

          otelcol.exporter.otlp "claude_code" {
            client {
              endpoint = "${tempoEndpoint}"
              // Tempo's gRPC receiver is plaintext on the Tailscale network.
              tls {
                insecure = true
              }
            }
          }
        '';
      };
    };
in
{
  flake.modules.nixos.otel-collector = module;
  flake.modules.darwin.otel-collector = module;
}
