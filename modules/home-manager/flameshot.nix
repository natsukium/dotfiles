{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.flameshot;
  iniFormat = pkgs.formats.ini { };
  iniFile = iniFormat.generate "flameshot.ini" cfg.settings;
in
{
  options.my.services = { inherit (options.services) flameshot; };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services = { inherit (config.my.services) flameshot; };
      })

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.packages = [ cfg.package ];

        xdg.configFile = lib.mkIf (cfg.settings != { }) {
          "flameshot/flameshot.ini".source = iniFile;
        };

        launchd.agents.flameshot = {
          enable = true;
          config = {
            ProgramArguments = [ "${cfg.package}/bin/flameshot" ];
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
