# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.nushell;
      completerCfg = config.ext.programs.nushell.externalCompleter;
    in
    {
      options.my.programs.nushell.enable = lib.mkEnableOption "nushell";

      options.ext.programs.nushell.externalCompleter = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.programs.nushell.enable;
        };
        enableFishCompleter = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          programs.nushell.enable = true;
        })

        (lib.mkIf completerCfg.enable {
          programs.nushell.extraConfig = lib.mkIf completerCfg.enableFishCompleter ''
            let fish_completer = {|spans|
                ${lib.getExe pkgs.fish} --command $'complete "--do-complete=($spans | str join " ")"'
                | $"value(char tab)description(char newline)" + $in
                | from tsv --flexible --no-infer
            }

            $env.config = ($env.config? | default {})
            $env.config.completions = ($env.config.completions? | default {})
            $env.config.completions.external = (
                $env.config.completions.external?
                | default {}
                | insert enable { true }
                | insert completer { $fish_completer }
            )
          '';
        })
      ];
    };
}
