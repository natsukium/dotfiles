{ self, withSystem, ... }:
{
  flake.modules.nixos."calibre-web" =
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
    };

  # The two init units are the part of this module that could silently stop
  # working: both run once at boot, and a failure leaves calibre-web serving an
  # empty library or an unusable admin account. Only a booted machine shows
  # that, hence a VM test rather than an evaluation check. It is named for one
  # system instead of coming out of `perSystem`, because the guest is what
  # manyara -- the only host serving calibre-web -- runs, not whatever machine
  # happens to evaluate the flake.
  flake.checks.x86_64-linux.calibre-web = withSystem "x86_64-linux" (
    { pkgs, ... }:
    pkgs.testers.runNixOSTest {
      name = "calibre-web";

      nodes.machine = {
        imports = [ self.modules.nixos.calibre-web ];

        services.calibre-web = {
          enable = true;
          options = {
            calibreLibrary = "/data/books";
          };
        };

        my.services.calibre-web = {
          adminPasswordFile = pkgs.runCommand "admin-password" { } ''
            echo "dummy-HDat1@WLJ&9AdSfc!MEH" > $out
          '';
        };
      };

      testScript = ''
        machine.wait_for_unit("calibre-web.service")

        # database should exist and be owned by calibre-web user
        machine.succeed("[ -f /data/books/metadata.db ]")
        machine.succeed("ls -l /data/books/metadata.db | grep \"calibre-web calibre-web\"")

        # admin password should be changed declaratively
        machine.wait_for_open_port(8083)
        machine.succeed("journalctl -u calibre-web-init-admin-password | grep \"Password for user 'admin' changed\"")
      '';
    }
  );
}
