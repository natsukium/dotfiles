{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  myCfg = config.my.services.calibre-web;
  cfg = config.services.calibre-web;
  emptyMetadataDB = pkgs.fetchurl {
    url = "https://github.com/janeczku/calibre-web/raw/refs/tags/0.6.23/library/metadata.db";
    hash = "sha256-+sL34370vA+ylV6aP2EmBHB9TvVzr1wovXqDaTOfS9Q=";
  };
in
{
  options = {
    my.services.calibre-web = {
      adminPasswordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.services.calibre-web-init-db = {
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "60";
        };
        wantedBy = [ "multi-user.target" ];
        before = [ "calibre-web.service" ];

        script = ''
          set -euo pipefail
          if [ ! -f ${cfg.options.calibreLibrary}/metadata.db ]; then
            install -Dm666 ${emptyMetadataDB} ${cfg.options.calibreLibrary}/metadata.db
            chown -R ${cfg.user}:${cfg.group} ${cfg.options.calibreLibrary}
          fi
        '';
      };
    }

    (mkIf (myCfg.adminPasswordFile != null) {
      systemd.services.calibre-web-init-admin-password = {
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "60";
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "calibre-web.service" ];
        requires = [ "calibre-web.service" ];

        path = [ config.services.calibre-web.package ];

        script =
          let
            dataDir = "/var/lib/${cfg.dataDir}";
          in
          ''
            set -euo pipefail
            calibre-web -p ${dataDir}/app.db -g ${dataDir}/gdrive.db -s "admin:$(cat ${myCfg.adminPasswordFile})"
          '';
      };
    })
  ]);
}
