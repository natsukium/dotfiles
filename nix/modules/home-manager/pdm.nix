{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.pdm;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.pdm = {
    enable = mkEnableOption ''
      A modern Python package manager with PEP 582 support
    '';
    package = mkOption {
      type = types.package;
      default = pkgs.pdm;
      description = "Package providing <command>pdm<command>.";
    };
    enablePEP582 = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable PEP582 globally.
        To make the Python interpreters aware of PEP 582 packages,
        one need to add the pdm/pep582/sitecustomize.py to
        the Python library search path.
      '';
    };
    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/pdm/config.toml</filename> on Linux or
        <filename>$HOME/Library/Preferences/pdm/config.toml</filename> on Darwin.
        </para><para>
        See <link xlink:href=https://pdm.fming.dev/latest/usage/configuration/"/>
        for the default configuration.
      '';
      example = literalExpression ''
        {
          install.cache = true;
        }
      '';
    };
  };

  config =
    let
      settings = cfg.settings // optionalAttrs (cfg.enablePEP582) { python.use_venv = false; };
    in
    mkIf cfg.enable (mkMerge [
      {
        home.packages = [ cfg.package ];
        home.sessionVariables = mkIf cfg.enablePEP582 {
          PYTHONPATH = "${pkgs.pdm}/${pkgs.python3.sitePackages}/pdm/pep582";
        };
      }

      (mkIf (settings != { }) {
        xdg.configFile."pdm/config.toml".source = tomlFormat.generate "config.toml" settings;
        home.sessionVariables = mkIf pkgs.stdenv.hostPlatform.isDarwin {
          PDM_CONFIG_FILE = "${config.xdg.configHome}/pdm/config.toml";
        };
      })
    ]);
}
