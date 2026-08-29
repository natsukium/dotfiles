{ inputs, ... }:
{
  # manyara evaluates every host's configuration to answer for the whole fleet, so
  # the scrape config, the alerts, and the drift job belong to the one machine that
  # watches the others rather than to comin itself.
  flake.modules.nixos.comin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      linux-machines = inputs.self.outputs.nixosConfigurations;
      darwin-machines = inputs.self.outputs.darwinConfigurations;

      textfileDir = config.my.services.node-exporter-textfile.directory;
      textfileName = "comin-drift";
      expectedCommitMetric = "comin_expected_commit_info";
      driftMetric = "comin_system_drift";

      dotfilesUrl = "https://github.com/natsukium/dotfiles";

      nodeExporterUser = config.services.prometheus.exporters.node.user;
      nodeExporterGroup = config.services.prometheus.exporters.node.group;

      cominTarget =
        name: value:
        let
          inherit (value.config.services.comin.exporter) listen_address port;
          listen_address' = if listen_address == "" then "localhost" else listen_address;
        in
        "${if name == config.networking.hostName then listen_address' else name}:${toString port}";

      machines = linux-machines // darwin-machines;
      isAlwaysOn = name: _: builtins.elem name config.my.services.victoriametrics.alwaysOnHosts;

      # One line per host, read by the drift checker below.
      hostSpecs = lib.mapAttrsToList (
        name: value:
        lib.concatStringsSep " " [
          name
          (if linux-machines ? ${name} then "nixosConfigurations" else "darwinConfigurations")
          (cominTarget name value)
          (if isAlwaysOn name value then "true" else "false")
        ]
      ) machines;
    in
    {
      # Everything here writes into VictoriaMetrics and vmalert, so the host that
      # runs them is the host that should watch the fleet's comin. Following that
      # option means manyara does not have to name this one at all.
      options.my.services.comin.monitoring.enable = lib.mkOption {
        type = lib.types.bool;
        default = config.my.services.victoriametrics.enable;
        defaultText = lib.literalExpression "config.my.services.victoriametrics.enable";
        description = "Whether to scrape, alert on, and derive drift from the fleet's comin.";
      };

      config = lib.mkIf config.my.services.comin.monitoring.enable {
        services.victoriametrics.prometheusConfig.scrape_configs = [
          {
            job_name = "comin";
            static_configs = [
              {
                labels.always_on = "true";
                targets = lib.mapAttrsToList cominTarget (lib.filterAttrs isAlwaysOn machines);
              }
              {
                targets = lib.mapAttrsToList cominTarget (lib.filterAttrs (name: v: !(isAlwaysOn name v)) machines);
              }
            ];
          }
        ];

        # Alerts on comin's own metrics live next to the scrape config and the drift
        # metric they read.
        services.vmalert.instances.main.rules.groups = [
          {
            name = "comin";
            rules = [
              {
                # Not an outage: the host serves everything it served before, it
                # just stops following main, so this is a warning while
                # InstanceDown stays critical. 15m because a switch legitimately
                # takes the exporter down for a few minutes.
                alert = "CominDown";
                expr = ''up{job="comin",always_on="true"} == 0'';
                for = "15m";
                labels.severity = "warning";
                annotations.summary = "comin on {{ $labels.instance }} is not answering; the host has stopped following main";
              }
              {
                alert = "CominDeploymentFailed";
                expr = ''comin_deployment_info{status="failed"} == 1'';
                for = "5m";
                labels.severity = "warning";
                annotations.summary = "comin deployment failed on {{ $labels.instance }} (commit {{ $labels.commit_id }})";
              }
              {
                # Always-on hosts only: a laptop asleep during a push is behind by
                # definition, and saying so every time it wakes was most of the noise
                # this alert used to make. 2h because a slow rebuild is not a fault
                # while the drift worth knowing about lasts days.
                alert = "CominSystemDrift";
                expr = ''${driftMetric}{always_on="true"} == 1'';
                for = "2h";
                labels.severity = "warning";
                annotations.summary = "{{ $labels.host }} is not running the system main HEAD evaluates to";
              }
              {
                # A commit that fails to evaluate or build never reaches a
                # deployment, so comin_deployment_info keeps reporting the previous
                # success. 15m so a broken commit I am already fixing stays quiet.
                alert = "CominEvalFailed";
                expr = "comin_last_eval_failed == 1";
                for = "15m";
                labels.severity = "warning";
                annotations.summary = "comin cannot evaluate the configuration on {{ $labels.instance }}";
              }
              {
                alert = "CominBuildFailed";
                expr = "comin_last_build_failed == 1";
                for = "15m";
                labels.severity = "warning";
                annotations.summary = "comin cannot build the configuration on {{ $labels.instance }}";
              }
              {
                alert = "CominFetchFailed";
                expr = ''comin_last_fetch_failed{always_on="true"} == 1'';
                for = "1h";
                labels.severity = "warning";
                annotations.summary = "comin on {{ $labels.instance }} cannot fetch {{ $labels.remote_name }}";
              }
              {
                # A suspended deployer stops applying commits while comin stays up,
                # keeps fetching, and every other gauge reads healthy.
                alert = "CominSuspended";
                expr = ''comin_is_suspended{always_on="true"} == 1'';
                for = "15m";
                labels.severity = "warning";
                annotations.summary = "comin on {{ $labels.instance }} is suspended and no longer deploying";
              }
              {
                # comin can wedge with its poller alive but never fetching again,
                # which no other gauge reflects. The window is this wide because the
                # fetcher also blocks while a new commit waits for a running build.
                alert = "CominStalled";
                expr = ''sum by (instance) (increase(comin_fetch_count{always_on="true"}[6h])) == 0'';
                for = "30m";
                labels.severity = "warning";
                annotations.summary = "comin on {{ $labels.instance }} has not fetched for hours";
              }
              {
                # 7d because a pending reboot is routine after a kernel update;
                # only a deferred one is worth a message.
                alert = "CominRebootRequired";
                expr = "comin_need_to_reboot == 1";
                for = "7d";
                labels.severity = "warning";
                annotations.summary = "{{ $labels.instance }} needs a reboot to activate its latest generation";
              }
            ];
          }
        ];

        my.services.node-exporter-textfile.enable = true;

        systemd.tmpfiles.rules = [
          # Folded into ${textfileName}.prom; left behind it would serve its last value forever.
          "r ${textfileDir}/${expectedCommitMetric}.prom"
        ];

        systemd.services.comin-drift = {
          description = "Publish per-host comin drift as a Prometheus textfile metric";
          serviceConfig = {
            Type = "oneshot";
            User = nodeExporterUser;
            Group = nodeExporterGroup;
            StateDirectory = "comin-drift";
            # nix wants a writable home for its evaluation and tarball caches.
            Environment = [ "HOME=%S/comin-drift" ];
            # Eight evaluations do not fit in the 90s a oneshot gets by default.
            TimeoutStartSec = "30m";
            ExecStart =
              let
                publishDrift = pkgs.writeShellApplication {
                  name = "comin-publish-drift";
                  runtimeInputs = [
                    config.nix.package
                    pkgs.coreutils
                    pkgs.curl
                    pkgs.findutils
                    pkgs.gawk
                    pkgs.git
                  ];
                  # comin deploys a store path, not a commit: it skips any commit whose
                  # closure it already runs and keeps reporting the older one that last
                  # changed the host, so comparing commit ids called every host a commit
                  # did not touch drifting. Evaluation is host-independent, so manyara
                  # can answer for the whole fleet and no other machine has to publish.
                  text = ''
                    main_commit=$(git ls-remote ${dotfilesUrl} refs/heads/main | cut -f1)
                    if [ -z "$main_commit" ]; then
                      echo "git ls-remote returned no SHA for refs/heads/main" >&2
                      exit 1
                    fi

                    repo=$STATE_DIRECTORY/repository
                    if [ ! -d "$repo/.git" ]; then
                      git clone --quiet ${dotfilesUrl} "$repo"
                    fi
                    git -C "$repo" fetch --quiet origin
                    mkdir -p "$STATE_DIRECTORY/eval" "$STATE_DIRECTORY/reported"

                    # A (host, commit) pair always evaluates to the same path.
                    eval_out_path() {
                      local cache
                      cache=$STATE_DIRECTORY/eval/$2.$1.$3
                      if [ ! -s "$cache" ]; then
                        # stdin is the host list the caller is looping over.
                        nix --extra-experimental-features 'nix-command flakes' --accept-flake-config eval --raw \
                          "git+file://$repo?rev=$3#$2.\"$1\".config.system.build.toplevel.outPath" \
                          </dev/null >"$cache.tmp" || return 1
                        mv "$cache.tmp" "$cache"
                      fi
                      cat "$cache"
                    }

                    # The gauge says a host is behind but not what by, and answering
                    # that from the dashboard would mean commit ids and store paths as
                    # metric labels. A log line carries free text at no such cost. The
                    # timer refires every five minutes and drift lasts days, so each
                    # (deployed, main) pair is reported once.
                    explain_drift() {
                      local host=$1 deployed=$2 expected=$3 actual=$4
                      local marker=$STATE_DIRECTORY/reported/$host

                      if [ "$(cat "$marker" 2>/dev/null || true)" = "$deployed $main_commit" ]; then
                        return 0
                      fi
                      printf '%s %s' "$deployed" "$main_commit" >"$marker"

                      echo "drift $host: running $deployed, main is $main_commit"
                      git -C "$repo" log --oneline --no-decorate "$deployed..$main_commit" 2>/dev/null |
                        awk -v h="$host" '{ print "drift " h ": missing " $0 }' || true

                      # diff-closures reads both closures from the local store, and
                      # another host's system is only here when manyara happened to
                      # build it, so the commit list above is the part always present.
                      if [ -n "$expected" ] && [ -e "$expected" ] && [ -e "$actual" ]; then
                        nix --extra-experimental-features 'nix-command' store diff-closures "$actual" "$expected" |
                          awk -v h="$host" 'NF { print "drift " h ": " $0 }' || true
                      fi
                    }

                    # The temp file deliberately does not end in .prom so the textfile
                    # collector skips it during the brief window before the rename.
                    tmp=$(mktemp ${textfileDir}/${textfileName}.XXXXXX.tmp)
                    {
                      printf '# HELP ${expectedCommitMetric} Latest commit on the configured branch, polled by systemd timer.\n'
                      printf '# TYPE ${expectedCommitMetric} gauge\n'
                      printf '${expectedCommitMetric}{branch="main",commit_id="%s"} 1\n' "$main_commit"
                      printf '# HELP ${driftMetric} Whether the host runs a system other than the one main HEAD evaluates to.\n'
                      printf '# TYPE ${driftMetric} gauge\n'
                    } >"$tmp"

                    while read -r host attr target always_on; do
                      # Unreachable or last-deployment-failed hosts belong to CominDown
                      # and CominDeploymentFailed; they get no drift series at all.
                      metrics=$(curl --silent --fail --max-time 5 "http://$target/metrics") || continue
                      deployed=$(printf '%s\n' "$metrics" | awk -F'"' '
                        /^comin_deployment_info\{/ && /status="done"/ {
                          for (i = 1; i < NF; i++) if ($i ~ /commit_id=$/) { print $(i + 1); exit }
                        }')
                      [ -n "$deployed" ] || continue

                      # Both stay empty on the rebase path below, where there is no
                      # pair of systems to compare; explain_drift reports what it has.
                      expected=""
                      actual=""

                      if [ "$deployed" = "$main_commit" ]; then
                        drift=0
                      elif ! git -C "$repo" merge-base --is-ancestor "$deployed" refs/remotes/origin/main; then
                        # comin refuses a branch that no longer contains what it deployed,
                        # and only says so in a debug log, so a rebased main strands the
                        # host with every gauge still reading healthy.
                        drift=1
                      else
                        expected=$(eval_out_path "$host" "$attr" "$main_commit") || continue
                        actual=$(eval_out_path "$host" "$attr" "$deployed") || continue
                        drift=0
                        [ "$expected" = "$actual" ] || drift=1
                      fi

                      # target duplicates the scrape address so the dashboard can join
                      # this against the comin job, whose instance label it cannot share.
                      printf '${driftMetric}{host="%s",target="%s",always_on="%s"} %s\n' \
                        "$host" "$target" "$always_on" "$drift" >>"$tmp"

                      if [ "$drift" = 1 ]; then
                        explain_drift "$host" "$deployed" "$expected" "$actual"
                      fi
                    done <<'SPECS'
                    ${lib.concatStringsSep "\n" hostSpecs}
                    SPECS

                    mv "$tmp" ${textfileDir}/${textfileName}.prom
                    find "$STATE_DIRECTORY/eval" -type f -mtime +30 -delete
                  '';
                };
              in
              lib.getExe publishDrift;
          };
        };

        systemd.timers.comin-drift = {
          description = "Refresh per-host comin drift metrics";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5m";
            OnUnitActiveSec = "5m";
          };
        };

        # Its own job so the explanations stay out of the comin log panel, which reads
        # one line per host rather than one per missing commit. Alloy parses all of
        # /etc/alloy as a single graph, so the sink from ./alloy.nix is reachable here;
        # a second source rather than another matcher because loki.source.journal ANDs
        # its matches.
        my.services.alloy.configs.comin-drift = ''
          loki.source.journal "comin_drift" {
            forward_to = [loki.relabel.comin.receiver]
            matches    = "_SYSTEMD_UNIT=comin-drift.service"
            labels     = {
              job  = "comin-drift",
              host = "${config.networking.hostName}",
              os   = "linux",
            }
          }
        '';
      };
    };
}
