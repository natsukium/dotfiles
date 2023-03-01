{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.pdm;
  tomlFormat = pkgs.formats.toml {};
  configDir =
    if pkgs.stdenv.isDarwin
    then "Library/Preferences"
    else config.xdg.configHome;
in {
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
      default = true;
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
      default = {};
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
    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };
    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };
    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];
    programs.bash.initExtra = mkIf (cfg.enableBashIntegration && cfg.enablePEP582) ''
      eval "$(${pkgs.pdm}/bin/pdm --pep582)"
    '';
    programs.zsh.initExtra = mkIf (cfg.enableZshIntegration && cfg.enablePEP582) ''
      eval "$(${pkgs.pdm}/bin/pdm --pep582)"
    '';
    programs.fish.interactiveShellInit = mkIf (cfg.enableFishIntegration && cfg.enablePEP582) ''
      eval (${pkgs.pdm}/bin/pdm --pep582 | source)
    '';
    home.file."${configDir}/pdm/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
