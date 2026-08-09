{ ... }:
{
  flake.modules.nixos.cloudflare-r2-exporter =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.cloudflare-r2-exporter;

      accountId = "dd87ce894022aec81eacd8ff1948438e";

      textfileDir = config.my.services.node-exporter-textfile.directory;
      textfileName = "cloudflare-r2";

      nodeExporterUser = config.services.prometheus.exporters.node.user;
      nodeExporterGroup = config.services.prometheus.exporters.node.group;

      publish = pkgs.writers.writePython3Bin "cloudflare-r2-publish-metrics" {
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./publish-metrics.py);
    in
    {
      # R2 publishes nothing to scrape: usage only exists in Cloudflare's GraphQL
      # analytics API.
      options.my.services.cloudflare-r2-exporter.enable =
        mkEnableOption "publishing Cloudflare R2 usage as Prometheus metrics";

      config = mkIf cfg.enable {
        my.services.node-exporter-textfile.enable = true;

        systemd.services.cloudflare-r2-exporter = {
          description = "Publish Cloudflare R2 usage as Prometheus textfile metrics";
          environment = {
            CLOUDFLARE_ACCOUNT_ID = accountId;
            TEXTFILE_PATH = "${textfileDir}/${textfileName}.prom";
          };
          serviceConfig = {
            Type = "oneshot";
            User = nodeExporterUser;
            Group = nodeExporterGroup;
            # Resolved by PID 1, so the secret itself stays root-only.
            LoadCredential = "api-token:${config.sops.secrets.cloudflare-analytics-token.path}";
            ExecStart = lib.getExe publish;
          };
        };

        systemd.timers.cloudflare-r2-exporter = {
          description = "Refresh Cloudflare R2 usage metrics";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5m";
            OnUnitActiveSec = "5m";
          };
        };

        services.prometheus.ruleFiles = [
          ((pkgs.formats.yaml { }).generate "cloudflare-r2-rules.yaml" {
            groups = [
              {
                name = "cloudflare-r2";
                rules = [
                  {
                    # Every panel on the R2 dashboard is a gauge the timer refreshes,
                    # so a failing timer leaves the last values on screen and nothing
                    # else says they stopped moving. An hour is twelve missed runs:
                    # past any transient API failure, well short of a wrong number
                    # being believed for a day.
                    alert = "CloudflareR2MetricsStale";
                    # The collector labels each file with its full path, not its
                    # name.
                    expr = ''time() - node_textfile_mtime_seconds{file="${textfileDir}/${textfileName}.prom"} > 3600'';
                    for = "15m";
                    labels.severity = "warning";
                    annotations.summary = "Cloudflare R2 usage metrics have not refreshed on {{ $labels.instance }}";
                  }
                ];
              }
            ];
          })
        ];

        # Created by hand under Manage Account > API Tokens as an account-owned
        # token, so it outlives any one member: a custom token carrying Account
        # Analytics: Read on the account above and nothing else.
        sops.secrets.cloudflare-analytics-token = {
          sopsFile = ./secrets.yaml;
        };
      };
    };
}
