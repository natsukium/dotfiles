{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.caffeinate;
in
{
  options = {
    my.services.caffeinate = {
      enable = lib.mkEnableOption "caffeinate, prevent system from sleeping";
      preventSleepOnCharge = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.caffeinate = {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/caffeinate"
        ]
        ++ lib.optional cfg.preventSleepOnCharge "-s"
        ++ lib.optional (cfg.args != [ ]) cfg.args;
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}
