{ ... }:
{
  flake.modules.nixos.prometheus =
    {
      inputs,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.prometheus;
      linux-machines = inputs.self.outputs.nixosConfigurations;
      darwin-machines = inputs.self.outputs.darwinConfigurations;
      yamlFormat = pkgs.formats.yaml { };

      # Every host enables the node exporter, so enablement cannot pick the ones
      # worth scraping: it would add the laptops, which are off far more than on
      # and would only contribute failed scrapes.
      nodeMetricsHosts = [
        "manyara"
        "serengeti"
        "mikumi"
        "kilimanjaro"
      ];
    in
    {
      options.my.services.prometheus.enable = mkEnableOption "Prometheus metrics server";

      config = mkIf cfg.enable {
        # Alerts on the metrics this server scrapes live next to the scrape
        # config. One generated file per module, not services.prometheus.rules:
        # that option joins its entries into a single file, and the YAML parser
        # keeps only the first document, so every group but the first is
        # silently dropped — promtool validates the truncated result and passes.
        services.prometheus.ruleFiles = [
          (yamlFormat.generate "infra-rules.yaml" {
            groups = [
              {
                name = "infra";
                rules = [
                  {
                    # Scoped to the comin job because comin runs on every host,
                    # making it the one target whose silence means the host
                    # itself is gone. always_on excludes the laptops and the
                    # on-demand builder, which are off far more often than not.
                    alert = "InstanceDown";
                    expr = ''up{job="comin",always_on="true"} == 0'';
                    for = "5m";
                    labels.severity = "critical";
                    annotations.summary = "{{ $labels.instance }} is unreachable";
                  }
                  {
                    # The node exporter's systemd collector turns every service
                    # crash into one metric, so this single rule covers all
                    # units without per-service exporters.
                    alert = "SystemdUnitFailed";
                    expr = ''node_systemd_unit_state{state="failed"} == 1'';
                    for = "5m";
                    labels.severity = "warning";
                    annotations.summary = "systemd unit {{ $labels.name }} failed on {{ $labels.instance }}";
                  }
                  {
                    # Aggregated by device: btrfs subvolumes mount at separate
                    # paths while drawing on one pool, so a single full disk
                    # would otherwise raise an identical alert per subvolume —
                    # four of them on kilimanjaro. The device is named rather
                    # than the mountpoint since that is what has to be freed.
                    alert = "FilesystemSpaceLow";
                    expr = ''max by (instance, device, fstype) (100 * node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"}) < 15'';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = ''{{ $labels.device }} on {{ $labels.instance }} below 15% free ({{ printf "%.1f" $value }}%)'';
                  }
                  {
                    alert = "FilesystemSpaceCritical";
                    expr = ''max by (instance, device, fstype) (100 * node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"}) < 5'';
                    for = "10m";
                    labels.severity = "critical";
                    annotations.summary = ''{{ $labels.device }} on {{ $labels.instance }} below 5% free ({{ printf "%.1f" $value }}%)'';
                  }
                  {
                    # apfs is excluded because macOS seals its root volume
                    # read-only by design, so the Darwin hosts would report a
                    # critical fault permanently.
                    alert = "FilesystemReadOnly";
                    expr = ''node_filesystem_readonly{fstype!~"tmpfs|ramfs|apfs"} == 1'';
                    for = "5m";
                    labels.severity = "critical";
                    annotations.summary = "{{ $labels.mountpoint }} on {{ $labels.instance }} is read-only";
                  }
                  {
                    alert = "OOMKillDetected";
                    expr = "increase(node_vmstat_oom_kill[10m]) > 0";
                    labels.severity = "warning";
                    annotations.summary = "OOM killer active on {{ $labels.instance }}";
                  }
                  {
                    alert = "MemoryPressureHigh";
                    expr = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 90";
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.instance }} memory above 90% for 30m";
                  }
                ];
              }
            ];
          })
        ];

        services.prometheus = {
          enable = true;
          scrapeConfigs = [
            {
              job_name = "node";
              # A single group, because listing a host under more than one meant
              # scraping it twice: every series it produced was stored once per
              # role label, so anything reading them counted a single fault as
              # several.
              static_configs = [
                {
                  targets = lib.mapAttrsToList (
                    name: value:
                    let
                      inherit (value.config.services.prometheus.exporters.node) listenAddress port;
                    in
                    "${if name == config.networking.hostName then listenAddress else name}:${toString port}"
                  ) (lib.filterAttrs (n: _: builtins.elem n nodeMetricsHosts) (linux-machines // darwin-machines));
                }
              ];
            }
          ];
        };
      };
    };
}
