{ lib, ... }:
let
  # Receives OTLP from coding agents on localhost and fans it out to manyara:
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
        lib.mkEnableOption "Alloy OTLP receiver for coding agent telemetry";

      config = lib.mkIf cfg.enable {
        # deltatocumulative is still experimental in Alloy.
        my.services.alloy.stabilityLevel = "experimental";

        my.services.alloy.configs.otlp = ''
          otelcol.receiver.otlp "coding_agents" {
            grpc {
              endpoint = "127.0.0.1:4317"
            }

            http {
              endpoint = "127.0.0.1:4318"
            }

            output {
              metrics = [otelcol.processor.transform.coding_agents.input]
              logs    = [otelcol.exporter.otlphttp.loki.input]
              traces  = [otelcol.exporter.otlp.tempo.input]
            }
          }

          // Codex and pi export delta sums, which the Prometheus exporter
          // drops, so they are accumulated here. pi gives each process its own
          // stream and seeds it at zero. Codex cannot seed a zero, so it keeps
          // one long-lived stream per label set: a fresh series per process
          // would lose its first sample to VictoriaMetrics' increase(), which
          // costs more than the rare concurrent export that ends no later
          // than one already accepted and is dropped. Claude Code's
          // cumulative streams pass through untouched.
          otelcol.processor.transform "coding_agents" {
            error_mode = "ignore"

            // codex.turn.cost_microusd is tagged per turn, which would make
            // every turn a single-sample series.
            metric_statements {
              context    = "datapoint"
              statements = [
                `delete_key(attributes, "turn.id")`,
                `delete_key(attributes, "conversation.id")`,
              ]
            }

            output {
              metrics = [otelcol.processor.deltatocumulative.coding_agents.input]
            }
          }

          otelcol.processor.deltatocumulative "coding_agents" {
            // Outlive the gaps between sessions, including weekends.
            max_stale = "168h"

            output {
              metrics = [otelcol.exporter.prometheus.coding_agents.input]
            }
          }

          otelcol.exporter.prometheus "coding_agents" {
            // Drop the unit and _total suffixes so metric names keep the
            // predictable <agent>_* form the dashboard queries against.
            add_metric_suffixes = false
            forward_to          = [prometheus.remote_write.manyara.receiver]
          }

          // Alloy names this component after the protocol, not the server;
          // VictoriaMetrics accepts remote_write on the same path.
          prometheus.remote_write "manyara" {
            // Agent metrics carry no host identity of their own; tag them
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

          otelcol.exporter.otlp "tempo" {
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
