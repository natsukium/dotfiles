{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  linux-machines = inputs.self.outputs.nixosConfigurations;
  darwin-machines = inputs.self.outputs.darwinConfigurations;

  textfileDir = "/var/lib/node-exporter-textfile";
  expectedCommitMetric = "comin_expected_commit_info";

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
  isAlwaysOn = name: _: builtins.elem name config.my.services.prometheus.alwaysOnHosts;
in
{
  services.prometheus.scrapeConfigs = [
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

  # Alerts on comin's own metrics live next to the scrape config and the
  # expected-commit metric they join against.
  services.prometheus.ruleFiles = [
    ((pkgs.formats.yaml { }).generate "comin-rules.yaml" {
      groups = [
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
              # comin marks the last deploy done even when newer commits exist on
              # origin, so a lagging host looks healthy; joining against the
              # main-HEAD textfile metric surfaces the drift.
              alert = "CominDeploymentDrift";
              expr = ''(comin_deployment_info{status="done"} unless on(commit_id) comin_expected_commit_info) and on() (count(comin_expected_commit_info) > 0)'';
              for = "30m";
              labels.severity = "warning";
              annotations.summary = "{{ $labels.instance }} is not on main HEAD (deployed {{ $labels.commit_id }})";
            }
            {
              alert = "CominRebootRequired";
              expr = ''comin_host_info{need_to_reboot="1"} == 1'';
              for = "15m";
              labels.severity = "warning";
              annotations.summary = "{{ $labels.instance }} needs a reboot to activate its latest generation";
            }
          ];
        }
      ];
    })
  ];

  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=${textfileDir}"
  ];

  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0700 ${nodeExporterUser} ${nodeExporterGroup} -"
  ];

  systemd.services.comin-expected-commit = {
    description = "Publish dotfiles main HEAD as a Prometheus textfile metric";
    serviceConfig = {
      Type = "oneshot";
      User = nodeExporterUser;
      Group = nodeExporterGroup;
      ExecStart =
        let
          # comin marks the last successful deployment as status=done regardless of
          # whether newer commits exist on origin, so a silently lagging host is
          # indistinguishable from a healthy one. Polling the remote main HEAD into a
          # textfile metric lets the dashboard join comin_deployment_info against the
          # expected value, surfacing drift directly.
          publishExpectedCommit = pkgs.writeShellApplication {
            name = "comin-publish-expected-commit";
            runtimeInputs = [
              pkgs.git
              pkgs.coreutils
            ];
            text = ''
              sha=$(git ls-remote ${dotfilesUrl} refs/heads/main | cut -f1)
              if [ -z "$sha" ]; then
                echo "git ls-remote returned no SHA for refs/heads/main" >&2
                exit 1
              fi

              # The temp file deliberately does not end in .prom so the textfile
              # collector skips it during the brief window before the rename.
              tmp=$(mktemp ${textfileDir}/${expectedCommitMetric}.XXXXXX.tmp)
              {
                printf '# HELP ${expectedCommitMetric} Latest commit on the configured branch, polled by systemd timer.\n'
                printf '# TYPE ${expectedCommitMetric} gauge\n'
                printf '${expectedCommitMetric}{branch="main",commit_id="%s"} 1\n' "$sha"
              } > "$tmp"
              mv "$tmp" ${textfileDir}/${expectedCommitMetric}.prom
            '';
          };
        in
        lib.getExe publishExpectedCommit;
    };
  };

  systemd.timers.comin-expected-commit = {
    description = "Refresh dotfiles main HEAD metric for drift detection";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
    };
  };
}
