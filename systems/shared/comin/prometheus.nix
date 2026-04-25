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
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "comin";
      static_configs = [
        {
          targets = lib.mapAttrsToList (
            name: value:
            let
              inherit (value.config.services.comin.exporter) listen_address port;
              listen_address' = if listen_address == "" then "localhost" else listen_address;
            in
            "${if name == config.networking.hostName then listen_address' else name}:${toString port}"
          ) (linux-machines // darwin-machines);
        }
      ];
    }
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
