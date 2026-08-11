{ ... }:
{
  flake.modules.nixos.tempo =
    { config, lib, ... }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.tempo;
      otlpGrpcPort = 4317;
      stateDir = "/var/lib/tempo";
    in
    {
      options.my.services.tempo.enable = mkEnableOption "Grafana Tempo trace backend";

      config = mkIf cfg.enable {
        services.tempo = {
          enable = true;

          # Tempo 3.x runs monolithic (target=all) without Kafka, but its rewritten
          # write path (live-store) and compaction coordinator (backend-scheduler)
          # replace the old ingester/compactor and default their working dirs to
          # /var/tempo -- outside the module's sandboxed StateDirectory. Every path
          # below is therefore pinned under /var/lib/tempo, or the service crashes
          # on a permission-denied mkdir at startup.
          settings = {
            server = {
              http_listen_port = 3200;
              # Loki already binds Tempo's default gRPC port (9095); move Tempo's
              # internal gRPC server off it. Nothing external targets this port --
              # trace ingestion goes through the OTLP receiver below.
              grpc_listen_port = 9096;
            };

            # Only the gRPC receiver is exposed: the fleet's Alloy instances push
            # traces over OTLP/gRPC, so the HTTP receiver would be an unused open
            # port. Bound to all interfaces because the pushers live on other
            # hosts (reachable over Tailscale), not localhost.
            distributor.receivers.otlp.protocols.grpc.endpoint = "0.0.0.0:${toString otlpGrpcPort}";

            storage.trace = {
              backend = "local";
              local.path = "${stateDir}/blocks";
              wal.path = "${stateDir}/wal";
            };

            live_store = {
              wal.path = "${stateDir}/live-store/traces";
              shutdown_marker_dir = "${stateDir}/live-store/shutdown-marker";
            };

            backend_scheduler.local_work_path = "${stateDir}/scheduler";

            # Retention moved out of the removed compactor into overrides. Match
            # Loki's 30-day window so traces and their correlated logs age out
            # together.
            overrides.defaults.compaction.block_retention = "720h";
          };
        };

        # Tailscale-only network, but firewall is still strict -- open the OTLP
        # gRPC port so Alloy clients on other hosts can push traces.
        networking.firewall.allowedTCPPorts = [ otlpGrpcPort ];
      };
    };
}
