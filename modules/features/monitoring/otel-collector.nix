{ lib, ... }:
let
  # Receives OTLP from Claude Code on localhost and fans the three signals out
  # to the central manyara stack: metrics via remote_write to Prometheus, logs
  # to Loki's native OTLP endpoint, and traces via OTLP to Tempo. Claude Code
  # sessions are too short-lived to scrape, so metrics have to be pushed like
  # the logs already are. Same body for nixos and darwin: it only appends an
  # alloy config snippet, and Alloy runs on both platforms via my.services.alloy.
  module =
    { config, inputs, ... }:
    let
      cfg = config.my.services.otel-collector;

      hostname = config.networking.hostName;
      manyara = inputs.self.outputs.nixosConfigurations.manyara.config;
      # Full tailnet FQDN, matching systems/shared/comin/alloy.nix: the short
      # name resolves inconsistently across Linux and macOS resolvers.
      host = "manyara.tail4108.ts.net";
      prometheusEndpoint = "http://${host}:${toString manyara.services.prometheus.port}/api/v1/write";
      # Loki's native OTLP ingest path. It promotes the service.name resource
      # attribute to a service_name label by default, so events are queryable as
      # {service_name="claude-code"} without hint plumbing on the Alloy side.
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
              logs    = [otelcol.exporter.otlphttp.loki.input]
              traces  = [otelcol.exporter.otlp.claude_code.input]
            }
          }

          otelcol.exporter.prometheus "claude_code" {
            // Drop the unit and _total suffixes so metric names keep the
            // predictable claude_code_* form the dashboard queries against.
            add_metric_suffixes = false
            forward_to          = [prometheus.remote_write.manyara.receiver]
          }

          prometheus.remote_write "manyara" {
            // Claude Code metrics carry no host identity of their own; tag them
            // here so the fleet's sessions are distinguishable in Grafana.
            external_labels = {
              host = "${hostname}",
            }

            endpoint {
              url = "${prometheusEndpoint}"
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
