{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.pueue;
  yamlFormat = pkgs.formats.yaml { };
  configFile = yamlFormat.generate "pueue.yml" ({ shared = { }; } // cfg.settings);
in
{
  options.my.services = { inherit (options.services) pueue; };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux { services = { inherit (config.my.services) pueue; }; })

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.packages = [ cfg.package ];
        home.file."Library/Application Support/pueue/pueue.yml".source = configFile;
        launchd.agents.pueued = {
          enable = true;
          config = {
            ProgramArguments = [
              "${cfg.package}/bin/pueued"
              "-v"
              "-c"
              "${configFile}"
            ];
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
