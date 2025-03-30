{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.copyq;
in
{
  options.my.services = { inherit (options.services) copyq; };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux { services = { inherit (config.my.services) copyq; }; })

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.packages = [ cfg.package ];
        launchd.agents.copyq = {
          enable = true;
          config = {
            ProgramArguments = [ "${cfg.package}/Applications/CopyQ.app/Contents/MacOS/CopyQ" ];
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
