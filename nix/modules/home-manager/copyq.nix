{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.copyq;
in
{
  # upstream has linux support only
  # https://github.com/nix-community/home-manager/blob/master/modules/services/copyq.nix
  disabledModules = [ "services/copyq.nix" ];

  options = with types; {
    services.copyq = {
      enable = mkEnableOption "CopyQ, a clipboard manager with advanced features";

      package = mkPackageOption pkgs "copyq" { };

      systemdTarget = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the CopyQ service.

          When setting this value to `"sway-session.target"`,
          make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
          otherwise the service may never be started.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.copyq = {
        Unit = {
          Description = "CopyQ clipboard management daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/copyq";
          Restart = "on-failure";
          Environment = [ "QT_QPA_PLATFORM=xcb" ];
        };

        Install = {
          WantedBy = [ cfg.systemdTarget ];
        };
      };
    })
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.copyq = {
        enable = true;
        config = {
          ProgramArguments = [ "${cfg.package}/Applications/CopyQ.app/Contents/MacOS/CopyQ" ];
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
    })
  ]);
}
