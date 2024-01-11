{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.bclm;
in
{
  options = with types; {
    services.bclm = {
      enable = mkEnableOption "BCLM, utility to limit max battery charge";
      package = mkPackageOption pkgs "bclm" { };
      value = mkOption {
        type = types.str;
        default = if pkgs.stdenv.isAarch64 then "80" else "77";
        description = "Value to set for max battery charge";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    launchd.daemons.bclm = {
      serviceConfig = {
        ProgramArguments = [
          "${cfg.package}/bin/bclm"
          "write"
          cfg.value
        ];
        RunAtLoad = true;
      };
    };
  };
}
