{ config, ... }:
let
  inherit (config.services.loki) dataDir;
in
{
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      # Set explicitly (matches Loki's default) so the firewall below and
      # the Grafana datasource URL can reference the canonical port via
      # config.services.loki.configuration.server.http_listen_port.
      server.http_listen_port = 3100;

      common = {
        path_prefix = dataDir;
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        ring.instance_addr = "127.0.0.1";
        storage.filesystem = {
          chunks_directory = "${dataDir}/chunks";
          rules_directory = "${dataDir}/rules";
        };
      };

      schema_config.configs = [
        {
          from = "2026-01-01";
          # tsdb is the recommended single-binary index since Loki 2.8 and
          # has fewer corruption modes than the legacy boltdb-shipper.
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      # tsdb-shipper requires an explicit active_index_directory; without it
      # /ready still passes (chunk store init succeeds) but every query
      # times out because the index path is undefined. Discovered the hard
      # way via curl /loki/api/v1/labels timing out at 5s on a freshly
      # provisioned host.
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "${dataDir}/tsdb-active";
          cache_location = "${dataDir}/tsdb-cache";
        };
        filesystem.directory = "${dataDir}/chunks";
      };

      # Retention is enforced by the compactor; the ingester alone does not
      # delete old data even if the schema rolls over.
      compactor = {
        working_directory = "${dataDir}/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config.retention_period = "720h"; # 30 days

      analytics.reporting_enabled = false;

      # Disable rule evaluator: we do not run alerting against Loki yet, and
      # without this the ruler logs noisy errors about a missing config dir.
      ruler.enable_api = false;
    };
  };

  # Tailscale-only network, but firewall is still strict — open Loki ingress
  # so Alloy clients on other hosts can push.
  networking.firewall.allowedTCPPorts = [
    config.services.loki.configuration.server.http_listen_port
  ];
}
