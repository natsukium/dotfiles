{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (inputs) nixbins;
  bins = nixbins.packages.${pkgs.stdenv.system};
  cfg = config.services.copyq;
in {
  options = with types; {
    services.copyq = {
      enable =
        mkEnableOption ''
        '';

      package = mkOption {
        type = path;
        default = bins.copyq;
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    launchd.user.agents.copyq = {
      serviceConfig = {
        ProgramArguments = ["${cfg.package}/Applications/CopyQ.app/Contents/MacOS/CopyQ"];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}
