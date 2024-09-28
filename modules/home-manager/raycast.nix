{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.raycast;
in
{
  options = with types; {
    services.raycast = {
      enable = mkEnableOption "Raycast";
      package = mkPackageOption pkgs "raycast" { };
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    launchd.agents.raycast = {
      enable = true;
      config = {
        ProgramArguments = [ "${cfg.package}/Applications/Raycast.app/Contents/MacOS/Raycast" ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}
