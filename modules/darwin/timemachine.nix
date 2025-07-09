{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.timemachine;
in
{
  options = {
    my.services.timemachine = {
      enableLocalSnapshot = lib.mkEnableOption "automatic local Time Machine snapshots";
      interval = lib.mkOption {
        description = "Interval between automatic snapshots in seconds";
        type = lib.types.int;
        default = 3600;
        example = 7200;
      };
    };
  };
  config = lib.mkIf cfg.enableLocalSnapshot {
    launchd.daemons.snapshot = {
      serviceConfig = {
        ProgramArguments = [
          "tmutil"
          "snapshot"
        ];
        RunAtLoad = true;
        StartInterval = cfg.interval;
      };
    };
  };
}
