{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.pueue;
in
{
  # the original module has no support for darwin and empty settings
  # see https://github.com/nix-community/home-manager/issues/4295
  disabledModules = [ "services/pueue.nix" ];

  options = with types; {
    services.pueue = {
      enable = mkEnableOption "Pueue, CLI process scheduler and manager";
      package = mkPackageOption pkgs "pueue" { };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.pueued = {
        Unit = {
          Description = "Pueue Daemon - CLI process scheduler and manager";
        };
        Service = {
          ExecStart = "${cfg.package}/bin/pueued -v";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    })

    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.pueued = {
        enable = true;
        config = {
          ProgramArguments = [
            "${cfg.package}/bin/pueued"
            "-v"
          ];
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
    })
  ]);
}
