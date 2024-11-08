{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  cfg = config.ext.services.nixpkgs-review;
in
{
  options = {
    ext.services.nixpkgs-review.autoDeleteLogs = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          format:
            GH_TOKEN=github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        '';
      };
    };
  };

  config = mkIf cfg.autoDeleteLogs.enable {
    systemd.services.nixpkgs-review-delete-old-logs = {
      startAt = "Sun 05:45";
      serviceConfig.EnvironmentFile = cfg.autoDeleteLogs.environmentFile;
      script = ''
        ${lib.getExe pkgs.gh} gist list --limit 1000 \
          | ${lib.getExe pkgs.gnugrep} "NixOS/nixpkgs/pull" \
          | ${lib.getExe pkgs.gawk} '{"date -d" $NF " +%s" | getline date; "date -d \"3 months ago\" +%s" | getline limit; if (date < limit) print $1}' \
          | ${lib.getExe' pkgs.findutils "xargs"} -n1 -t ${lib.getExe pkgs.gh} gist delete
      '';
    };
  };
}
