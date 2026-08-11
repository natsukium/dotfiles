{ ... }:
{
  # macOS has no systemd, so node_systemd_unit_state -- the metric the
  # SystemdUnitFailed alert leans on -- never exists on the Darwin hosts, and the
  # upstream node exporter ships no launchd collector. A KeepAlive daemon that
  # dies and is never restarted (as comin once did, unnoticed for weeks) leaves
  # no trace in metrics. Emit that state through the textfile collector so the
  # same class of failure is visible on macOS.
  flake.modules.darwin.launchd-health =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.launchd-health;

      textfileDir = "/var/lib/node-exporter-textfile";
      nodeExporterUser = config.services.prometheus.exporters.node.user;

      # launchctl list <label> resolves in the caller's domain, so it must run as
      # root to see the system-domain daemons; the launchd job below does.
      probeLaunchd = pkgs.writeShellApplication {
        name = "launchd-health-probe";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          mkdir -p ${textfileDir}
          tmp=$(mktemp ${textfileDir}/launchd_health.XXXXXX.tmp)
          {
            printf '# HELP launchd_keepalive_daemon_running A managed KeepAlive LaunchDaemon has a running process (1) or not (0).\n'
            printf '# TYPE launchd_keepalive_daemon_running gauge\n'
            for plist in /Library/LaunchDaemons/*.plist; do
              label=$(plutil -extract Label raw -o - "$plist" 2>/dev/null) || continue
              case "$label" in
                org.nixos.*|com.github.nlewo.*|com.dotfiles.*) ;;
                *) continue ;;
              esac
              # Only bool-true KeepAlive is an always-on daemon. Absent means a
              # one-shot (activation, nix-gc) whose stopped state is normal; a
              # dict means conditional restart, which we cannot judge from here.
              ka=$(plutil -extract KeepAlive xml1 -o - "$plist" 2>/dev/null) || continue
              case "$ka" in
                *"<true/>"*) ;;
                *) continue ;;
              esac
              if launchctl list "$label" 2>/dev/null | grep -qE '"PID"[[:space:]]*='; then
                running=1
              else
                running=0
              fi
              printf 'launchd_keepalive_daemon_running{label="%s"} %d\n' "$label" "$running"
            done
          } > "$tmp"
          # The temp name lacks the .prom suffix the collector matches, so a
          # half-written file is never scraped; the rename publishes atomically.
          mv "$tmp" ${textfileDir}/launchd_health.prom
        '';
      };
    in
    {
      options.my.services.launchd-health.enable =
        mkEnableOption "launchd KeepAlive daemon liveness as a node exporter textfile metric";

      config = mkIf cfg.enable {
        services.prometheus.exporters.node.extraFlags = [
          "--collector.textfile.directory=${textfileDir}"
        ];

        launchd.daemons.launchd-health = {
          serviceConfig = {
            Label = "com.dotfiles.launchd-health";
            ProgramArguments = [ (lib.getExe probeLaunchd) ];
            RunAtLoad = true;
            StartInterval = 60;
            StandardErrorPath = "/var/log/launchd-health.err.log";
          };
        };

        system.activationScripts.launchdHealthDir.text = ''
          mkdir -p ${textfileDir}
          chown ${nodeExporterUser} ${textfileDir}
          chmod 755 ${textfileDir}
        '';
      };
    };
}
