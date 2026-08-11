{ ... }:
{
  flake.modules.nixos.victoriametrics =
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
      cfg = config.my.services.victoriametrics;
      linux-machines = inputs.self.outputs.nixosConfigurations;
      darwin-machines = inputs.self.outputs.darwinConfigurations;
      yamlFormat = pkgs.formats.yaml { };

      vmalertAddress = "127.0.0.1:${toString cfg.vmalertPort}";
      vmalertUrl = "http://${vmalertAddress}";
      vmUrl = "http://127.0.0.1:${toString cfg.port}";

      # The backup below deletes every snapshot around its run, so this
      # directory holds exactly one while restic reads it.
      snapshotDir = "/var/lib/${config.services.victoriametrics.stateDir}/snapshots";

      # Not derived from exporter enablement: every host enables it, and
      # scraping the mostly-off laptops would only record failures.
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
      options.my.services.victoriametrics = {
        enable = mkEnableOption "VictoriaMetrics metrics server with vmalert";

        # An option because otel-collector on the other machines reads it to
        # build the remote-write URL; listenAddress is a bind spec rather than
        # something to parse.
        port = mkOption {
          type = types.port;
          default = 8428;
          description = "Port VictoriaMetrics serves its HTTP API on.";
        };

        # Loopback only. Nothing off this host talks to vmalert directly:
        # Grafana reaches its rule API through the database, which proxies.
        vmalertPort = mkOption {
          type = types.port;
          default = 8880;
          description = "Port vmalert serves its HTTP API on.";
        };

        # Hosts whose silence is a fault rather than routine; everything else
        # is a laptop or the on-demand builder. Not derived from
        # my.profiles.server, which describes how a host is built, not whether
        # its disappearance should page. An option because the comin scrape
        # config labels its targets from the same set.
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
        services.victoriametrics = {
          enable = true;
          listenAddress = ":${toString cfg.port}";
          # Long enough to compare a sensor against the same season years
          # back; at the measured rate five years is tens of gigabytes. Left
          # unset this would mean one month, not forever.
          retentionPeriod = "5y";

          extraOptions = [
            # VictoriaMetrics infers staleness from the observed gap between
            # samples, but the `up == 0` alerts assume Prometheus' fixed five
            # minutes, so pin it before a scrape-interval change moves when
            # they fire.
            "-search.maxLookback=5m"

            # Grafana's Prometheus datasource looks for /api/v1/rules and
            # /api/v1/alerts on the datasource itself; here they live in
            # vmalert, so proxy rather than add a second datasource.
            "-vmalert.proxyURL=${vmalertUrl}"
          ];

          prometheusConfig = {
            # promscrape documents no default, and the interval sets the
            # storage rate the retention above is sized from.
            global.scrape_interval = "1m";

            scrape_configs = [
              {
                job_name = "node";
                # Two groups so InstanceDown can tell the always-on hosts
                # apart; kept disjoint because a host in both would be scraped
                # twice.
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
              {
                # The one component whose failure hides every other failure.
                # vmalert is included because it going quiet stops alerting
                # just as completely as the database going quiet.
                job_name = "victoriametrics";
                static_configs = [
                  {
                    targets = [
                      "127.0.0.1:${toString cfg.port}"
                      vmalertAddress
                    ];
                  }
                ];
              }
            ];
          };
        };

        services.vmalert.instances.main = {
          enable = true;
          settings = {
            "datasource.url" = vmUrl;
            "httpListenAddr" = vmalertAddress;
            # vmalert keeps pending-alert state in memory and comin restarts
            # the unit on every deploy; without persisting that state every
            # `for` timer would reset, and CominRebootRequired's seven days
            # would never elapse.
            "remoteWrite.url" = vmUrl;
            "remoteRead.url" = vmUrl;
            # Alertmanager groups on alertname and instance, so the group-name
            # label vmalert adds would only clutter the Matrix messages.
            disableAlertgroupLabel = true;
          };

          # One group per module, next to the scrape config that feeds it;
          # contributions from other modules merge as a list.
          rules.groups = [
            {
              name = "infra";
              rules = [
                {
                  # Scoped to the node job: comin's exporter can die while the
                  # host is healthy, and that case is CominDown instead.
                  alert = "InstanceDown";
                  expr = ''up{job="node",always_on="true"} == 0'';
                  for = "5m";
                  labels.severity = "critical";
                  annotations.summary = "{{ $labels.instance }} is unreachable";
                }
                {
                  alert = "SystemdUnitFailed";
                  expr = ''node_systemd_unit_state{state="failed"} == 1'';
                  for = "5m";
                  labels.severity = "warning";
                  annotations.summary = "systemd unit {{ $labels.name }} failed on {{ $labels.instance }}";
                }
                {
                  # Aggregated by device: btrfs subvolumes draw on one pool,
                  # so a full disk would otherwise alert once per subvolume.
                  # The device is named because that is what has to be freed.
                  alert = "FilesystemSpaceLow";
                  expr = ''max by (instance, device, fstype) (100 * node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"}) < 15'';
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = ''{{ $labels.device }} on {{ $labels.instance }} below 15% free ({{ printf "%.1f" $value }}%)'';
                }
                {
                  # Watches /boot, which the 15% rule skips: manyara's 128MiB
                  # ESP normally sits at 15% free, but below 5% a kernel no
                  # longer fits and deploys fail at the bootloader step, which
                  # once went unnoticed for a week.
                  alert = "FilesystemSpaceCritical";
                  expr = ''max by (instance, device, fstype) (100 * node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay"}) < 5'';
                  for = "10m";
                  labels.severity = "critical";
                  annotations.summary = ''{{ $labels.device }} on {{ $labels.instance }} below 5% free ({{ printf "%.1f" $value }}%)'';
                }
                {
                  # apfs is sealed read-only by design and readOnlyNixStore
                  # binds /nix/store read-only deliberately. A disk that
                  # genuinely fails flips the whole superblock, so / and /home
                  # still alert.
                  alert = "FilesystemReadOnly";
                  expr = ''node_filesystem_readonly{fstype!~"tmpfs|ramfs|apfs",mountpoint!="/nix/store"} == 1'';
                  for = "5m";
                  labels.severity = "critical";
                  annotations.summary = "{{ $labels.mountpoint }} on {{ $labels.instance }} is read-only";
                }
                {
                  # SystemdUnitFailed only catches runs that start and then
                  # fail; the timer's last trigger is the one signal for runs
                  # that never start. Timers that have not fired since boot
                  # report zero, hence the second term.
                  alert = "BackupStale";
                  expr = ''time() - node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.*"} > 172800 and node_systemd_timer_last_trigger_seconds > 0'';
                  for = "1h";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.name }} has not run in two days on {{ $labels.instance }}";
                }
                {
                  alert = "OOMKillDetected";
                  expr = "increase(node_vmstat_oom_kill[10m]) > 0";
                  labels.severity = "warning";
                  annotations.summary = "OOM killer active on {{ $labels.instance }}";
                }
                {
                  # The Darwin node exporter lacks the Linux memory metrics,
                  # so the first term never matches there; the fallback leaves
                  # out inactive memory, which macOS reclaims on demand.
                  alert = "MemoryPressureHigh";
                  expr = "(100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or 100 * ((node_memory_active_bytes + node_memory_wired_bytes + node_memory_compressed_bytes) / node_memory_total_bytes)) > 90";
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.instance }} memory above 90% for 30m";
                }
                {
                  # The macOS counterpart of SystemdUnitFailed, fed by the
                  # launchd-health textfile job. 15m so a daemon restarting
                  # between scrapes does not page.
                  alert = "LaunchdDaemonDown";
                  expr = "launchd_keepalive_daemon_running == 0";
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.label }} is not running on {{ $labels.instance }}";
                }
              ];
            }
            {
              # Each of these is a way for alerting to stop working while
              # every dashboard still looks healthy.
              name = "victoriametrics";
              rules = [
                {
                  # A rejected config leaves the previous one running, so a
                  # deploy that did not take looks like nothing changed.
                  alert = "MetricsConfigReloadFailed";
                  expr = "vm_promscrape_config_last_reload_successful == 0";
                  for = "5m";
                  labels.severity = "critical";
                  annotations.summary = "VictoriaMetrics is still running an older scrape config than the one deployed";
                }
                {
                  alert = "AlertRuleEvaluationFailing";
                  expr = "increase(vmalert_execution_errors_total[15m]) > 0";
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "vmalert cannot evaluate its rules";
                }
                {
                  # Delivery failing is indistinguishable from nothing being
                  # wrong, which is the one failure that hides all the others.
                  alert = "AlertNotificationFailing";
                  expr = "increase(vmalert_alerts_send_errors_total[15m]) > 0";
                  for = "15m";
                  labels.severity = "critical";
                  annotations.summary = "vmalert cannot deliver alerts to Alertmanager";
                }
              ];
            }
          ];
        };

        # vmalert queries the database rather than evaluating in-process, so
        # starting it first only produces a burst of connection failures.
        systemd.services.vmalert-main = {
          after = [ "victoriametrics.service" ];
          wants = [ "victoriametrics.service" ];
        };

        # Alloy on the other hosts pushes the Claude Code metrics here over
        # remote_write; ephemeral CLI sessions cannot be scraped.
        networking.firewall.allowedTCPPorts = [ cfg.port ];

        # Losing this host would cost years of house history, and the archive
        # is single-digit gigabytes. The database rewrites its files as it
        # merges parts, so restic cannot read the live directory; a snapshot
        # freezes one view as hardlinks, costing directory entries and nothing
        # else.
        my.services.restic.backups.victoriametrics = {
          paths = [ snapshotDir ];
          prepare = ''
            # Clearing first handles a run killed between prepare and cleanup,
            # and means this never has to learn the generated snapshot name.
            ${lib.getExe pkgs.curl} -fsS -XPOST ${vmUrl}/snapshot/delete_all >/dev/null
            ${lib.getExe pkgs.curl} -fsS -XPOST ${vmUrl}/snapshot/create >/dev/null
          '';
          cleanup = ''
            ${lib.getExe pkgs.curl} -fsS -XPOST ${vmUrl}/snapshot/delete_all >/dev/null
          '';
        };

        # system.checks rather than extraDependencies: these only have to build,
        # and nothing they produce belongs in the running system's closure.
        system.checks = [
          # checkConfig already rejects unparsable YAML, but a scrape_config
          # failing its semantic validation is only logged and skipped while
          # the process exits 0, so grep for the line it prints.
          (pkgs.runCommand "victoriametrics-scrape-config-check" { } ''
            set -o pipefail
            ${lib.getExe' config.services.victoriametrics.package "victoria-metrics"} \
              -promscrape.config=${yamlFormat.generate "promscrape.yaml" config.services.victoriametrics.prometheusConfig} \
              -dryRun 2>&1 | tee check.log
            if grep -q 'skipping `scrape_config`' check.log; then
              echo "a scrape_config failed validation and would be silently dropped" >&2
              exit 1
            fi
            # If a future release renames the skip line, fail rather than pass
            # on any output at all.
            grep -q -- '-promscrape.config is ok' check.log
            touch $out
          '')

          # vmalert ships no promtool equivalent, so a typo in an expression
          # would otherwise only surface as a rule stuck in an error state.
          (pkgs.runCommand "vmalert-rules-check" { } ''
            ${lib.getExe' config.services.vmalert.package "vmalert"} \
              -rule=${yamlFormat.generate "vmalert-rules.yaml" config.services.vmalert.instances.main.rules} \
              -dryRun
            touch $out
          '')
        ];
      };
    };
}
