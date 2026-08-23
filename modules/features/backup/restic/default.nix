{ ... }:
{
  flake.modules.nixos.restic =
    {
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
      cfg = config.my.services.restic;

      # One repository per backup instead of one per host. `restic forget
      # --prune` takes an exclusive lock on its repository, so services sharing
      # one would queue behind each other every night, and a restore only ever
      # wants a single service's snapshots. What that gives up is deduplication
      # between a git server, a feed reader and a Matrix database, which have
      # nothing in common to deduplicate.
      repositoryOf =
        name:
        "s3:https://${cfg.accountId}.r2.cloudflarestorage.com/${cfg.bucket}/${config.networking.hostName}/${name}";

      # restic writes the hook to a file and executes it, so it needs its own
      # shebang and its own strict mode; without set -e a command failing
      # halfway through a hook would go unnoticed and the snapshot would be
      # taken anyway.
      hookScript =
        script:
        if script == null then
          null
        else
          ''
            #!${pkgs.runtimeShell}
            set -euo pipefail
            ${script}
          '';
    in
    {
      # Backups go off-site to Cloudflare R2 rather than to a second disk,
      # because the failure I want to survive is losing the box or the room it
      # sits in, not losing one drive. R2 charges nothing for egress, so a
      # restore drill costs only the API calls it makes.
      #
      # Bootstrap, once, by hand:
      #
      # 1. terraform apply in infra/global/domains/natsukium-com to create the
      #    bucket.
      # 2. Mint an R2 API token scoped to that bucket with Object Read & Write
      #    in the Cloudflare dashboard; the Terraform provider cannot create
      #    API tokens.
      # 3. openssl rand -base64 32   # the repository password
      # 4. sops modules/features/backup/restic/secrets.yaml and fill in
      #    restic-password and restic-r2-credentials, the latter holding
      #    AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY lines.
      #
      # Every backup also installs a `restic-<name>` wrapper with the
      # repository and credentials already in its environment, so a restore is
      # `restic-forgejo snapshots` followed by `restic-forgejo restore latest
      # --target /restore`.
      options.my.services.restic = {
        enable = mkEnableOption "off-site backups to Cloudflare R2";

        accountId = mkOption {
          type = types.str;
          default = "dd87ce894022aec81eacd8ff1948438e";
          description = "Cloudflare account that owns the R2 bucket.";
        };

        bucket = mkOption {
          type = types.str;
          default = "restic-backup";
          description = "R2 bucket holding every host's repositories.";
        };

        pruneOpts = mkOption {
          type = types.listOf types.str;
          default = [
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
          ];
          description = "Retention applied by `restic forget --prune` after each run.";
        };

        backups = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                paths = mkOption {
                  type = types.listOf types.str;
                  description = "Files and directories to snapshot.";
                };

                exclude = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Patterns dropped from {option}`paths`.";
                };

                prepare = mkOption {
                  type = types.nullOr types.lines;
                  default = null;
                  description = ''
                    Shell run as root before the snapshot, for services that
                    cannot be copied while live. A non-zero exit aborts the run.
                  '';
                };

                cleanup = mkOption {
                  type = types.nullOr types.lines;
                  default = null;
                  description = ''
                    Shell run as root after the run, whether or not it
                    succeeded, to undo what {option}`prepare` did.
                  '';
                };

                startAt = mkOption {
                  type = types.str;
                  default = "*-*-* 03:00:00";
                  description = "When the backup timer fires, before jitter.";
                };
              };
            }
          );
          default = { };
          description = "Backups taken on this host, one repository each.";
        };
      };

      config = mkIf cfg.enable {
        services.restic.backups = lib.mapAttrs (name: backup: {
          repository = repositoryOf name;
          passwordFile = config.sops.secrets.restic-password.path;
          environmentFile = config.sops.secrets.restic-r2-credentials.path;
          initialize = true;

          # R2 has no regions, but the S3 client still needs one and would
          # otherwise spend a request asking the bucket where it lives.
          extraOptions = [ "s3.region=auto" ];

          inherit (backup) paths exclude;
          inherit (cfg) pruneOpts;

          backupPrepareCommand = hookScript backup.prepare;
          backupCleanupCommand = hookScript backup.cleanup;

          timerConfig = {
            OnCalendar = backup.startAt;
            # The jitter keeps the backups from all opening their R2
            # connections on the same second; Persistent catches up a run the
            # host slept through.
            RandomizedDelaySec = "45m";
            Persistent = true;
          };
        }) cfg.backups;

        sops.secrets = {
          restic-password.sopsFile = ./secrets.yaml;
          restic-r2-credentials.sopsFile = ./secrets.yaml;
        };
      };
    };
}
