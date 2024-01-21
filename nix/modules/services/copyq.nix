{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  nurpkgs = config.nur.repos.natsukium;
  cfg = config.services.copyq;
in
{
  options = with types; {
    services.copyq = {
      enable = mkEnableOption "";

      package = mkOption {
        type = path;
        default = nurpkgs.copyq;
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.copyq = {
      serviceConfig = {
        ProgramArguments = [ "${cfg.package}/Applications/CopyQ.app/Contents/MacOS/CopyQ" ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}
