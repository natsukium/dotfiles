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
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        types
        ;
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

      nodeTarget =
        name: value:
        let
          inherit (value.config.services.prometheus.exporters.node) listenAddress port;
        in
        "${if name == config.networking.hostName then listenAddress else name}:${toString port}";

      nodeMachines = lib.filterAttrs (n: _: builtins.elem n nodeMetricsHosts) (
        linux-machines // darwin-machines
      );
      isAlwaysOn = name: _: builtins.elem name cfg.alwaysOnHosts;
    in
    {
      options.my.services.prometheus = {
        enable = mkEnableOption "Prometheus metrics server";

        # Hosts expected to answer around the clock, so their silence is a fault
        # worth paging on. Everything else is a laptop or tarangire, the
        # on-demand builder kept powered off for its consumption; those going
        # quiet is routine. Deliberately not derived from my.profiles.server:
        # that profile describes how a host is built, not whether anyone should
        # be woken when it disappears. An option rather than a local list
        # because the comin scrape config labels its targets from the same set.
        alwaysOnHosts = mkOption {
          type = types.listOf types.str;
          default = [
            "manyara"
            "serengeti"
            "mikumi"
          ];
          description = "Hosts whose silence should raise a critical alert.";
        };
      };

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
                    # Scoped to the node job, not comin: comin's exporter can
                    # die while the machine behind it is healthy, and only the
                    # node exporter goes quiet exactly when the host does.
                    # comin having stopped is CominDown instead.
                    alert = "InstanceDown";
                    expr = ''up{job="node",always_on="true"} == 0'';
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
                    # Unlike the 15% rule this one watches /boot as well.
                    # manyara's ESP is 128MiB and normally sits at 15% free, so
                    # warning there would fire permanently, but 5% is the point
                    # where a kernel no longer fits and comin's deploys start
                    # failing at the bootloader step — which is how a full ESP
                    # went unnoticed for a week.
                    alert = "FilesystemSpaceCritical";
                    expr = ''max by (instance, device, fstype) (100 * node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay"}) < 5'';
                    for = "10m";
                    labels.severity = "critical";
                    annotations.summary = ''{{ $labels.device }} on {{ $labels.instance }} below 5% free ({{ printf "%.1f" $value }}%)'';
                  }
                  {
                    # apfs is excluded because macOS seals its root volume
                    # read-only by design, so the Darwin hosts would report a
                    # critical fault permanently. /nix/store goes with it:
                    # boot.readOnlyNixStore binds it read-only over a writable
                    # subvolume. A disk that genuinely turns read-only flips the
                    # whole superblock, so / and /home keep raising the alert.
                    alert = "FilesystemReadOnly";
                    expr = ''node_filesystem_readonly{fstype!~"tmpfs|ramfs|apfs",mountpoint!="/nix/store"} == 1'';
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
                    # The macOS node exporter exposes none of the Linux memory
                    # metrics, so the first term never matches the Darwin hosts.
                    # The fallback term approximates used memory there as
                    # active + wired + compressed, leaving out inactive since
                    # macOS can reclaim it on demand.
                    alert = "MemoryPressureHigh";
                    expr = "(100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or 100 * ((node_memory_active_bytes + node_memory_wired_bytes + node_memory_compressed_bytes) / node_memory_total_bytes)) > 90";
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.instance }} memory above 90% for 30m";
                  }
                  {
                    # The macOS equivalent of SystemdUnitFailed: the metric comes
                    # from the launchd-health textfile job on the Darwin hosts,
                    # since the node exporter has no launchd collector. 15m so a
                    # daemon restarting between scrapes does not page.
                    alert = "LaunchdDaemonDown";
                    expr = "launchd_keepalive_daemon_running == 0";
                    for = "15m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.label }} is not running on {{ $labels.instance }}";
                  }
                ];
              }
            ];
          })
        ];

        # Tailscale-only network, but firewall is still strict -- open the
        # Prometheus port so Alloy clients on other hosts can remote_write the
        # push-only Claude Code metrics (ephemeral CLI sessions cannot be
        # scraped).
        networking.firewall.allowedTCPPorts = [ config.services.prometheus.port ];

        services.prometheus = {
          enable = true;
          # The remote-write receiver is off by default; without it the fleet's
          # Alloy has nowhere to push the OTLP-sourced Claude Code metrics.
          extraFlags = [ "--web.enable-remote-write-receiver" ];
          scrapeConfigs = [
            {
              job_name = "node";
              # Two groups only because InstanceDown needs to tell the
              # always-on hosts apart, and they are kept disjoint: listing a
              # host under both would scrape it twice, storing every series it
              # produces once per label set, so anything reading them would
              # count a single fault as several.
              static_configs = [
                {
                  labels.always_on = "true";
                  targets = lib.mapAttrsToList nodeTarget (lib.filterAttrs isAlwaysOn nodeMachines);
                }
                {
                  targets = lib.mapAttrsToList nodeTarget (lib.filterAttrs (n: v: !(isAlwaysOn n v)) nodeMachines);
                }
              ];
            }
          ];
        };
      };
    };
}
