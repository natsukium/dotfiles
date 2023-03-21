{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.sketchybar;
  configFile = "${pkgs.writeScript "sketchybarrc" cfg.config}";
in {
  options.services.sketchybar.enable = mkEnableOption ''
    Whether to enable the sketchybar.
  '';

  options.services.sketchybar.package = mkOption {
    type = types.path;
    default = pkgs.sketchybar;
    description = "The sketcybar package to use.";
  };

  options.services.sketchybar.config = mkOption {
    type = types.str;
    default = "";
    example =
      literalExpression ''
      '';
    description = ''
      Configuration written to sketchybarrc.
    '';
  };

  options.services.sketchybar.hideMenuBar = mkOption {
    type = types.bool;
    default = true;
    description = "Whether to hide the default menu bar.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    launchd.user.agents.sketchybar = {
      serviceConfig = {
        ProgramArguments =
          ["${cfg.package}/bin/sketchybar"]
          ++ optionals (cfg.config != "") ["--config" configFile];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          PATH = "${cfg.package}/bin:${config.environment.systemPath}";
        };
      };
    };

    system.defaults.NSGlobalDomain._HIHideMenuBar = cfg.hideMenuBar;
  };
}
