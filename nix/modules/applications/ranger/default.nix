{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.ranger;
in {
  options.programs.ranger = {
    enable = mkEnableOption "ranger";

    package = mkOption {
      type = types.package;
      default = pkgs.ranger;
      description = "The ranger package to use";
    };

    enableUeberzug = mkOption {
      type = types.bool;
      default = true;
      description = "Enable ueberzug support";
    };

    ueberzugPackage = mkOption {
      type = types.package;
      default = pkgs.ueberzugpp;
      description = "The ueberzug package to use";
    };

    settings = mkOption {
      type = types.lines;
      default = "";
      description = "Settings to add to the ranger config";
      example = literalExpression ''
        set preview_images_method ueberzug
        set preview_images true
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      [cfg.package]
      ++ lib.optionals cfg.enableUeberzug [
        cfg.ueberzugPackage
      ];

    xdg.configFile."ranger/rc.conf".text =
      lib.optionalString (cfg.settings != "") cfg.settings
      + lib.optionalString cfg.enableUeberzug ''
        set preview_images_method ueberzug
      '';
  };
}
