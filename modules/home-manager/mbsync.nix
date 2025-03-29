{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.mbsync;
  mbsyncOptions =
    [ "--all" ]
    ++ lib.optional (cfg.verbose) "--verbose"
    ++ lib.optional (cfg.configFile != null) "--config ${cfg.configFile}";
in
{
  options.my.services = { inherit (options.services) mbsync; };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services = { inherit (config.my.services) mbsync; };
      })

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        launchd.agents.mbsync = {
          enable = true;
          config = {
            ProgramArguments = [ "${lib.getExe cfg.package}" ] ++ mbsyncOptions;
            RunAtLoad = true;
            StartInterval = 300;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mbsync/stdout";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mbsync/stderr";
          };
        };
      })
    ]
  );
}
