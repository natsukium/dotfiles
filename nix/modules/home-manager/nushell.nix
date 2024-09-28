{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.ext.programs.nushell;
in
{
  options = {
    ext.programs.nushell.externalCompleter = {
      enable = mkOption {
        type = types.bool;
        default = config.programs.nushell.enable;
      };
      enableFishCompleter = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };
  config = mkIf cfg.externalCompleter.enable {
    programs.nushell.extraConfig = mkIf cfg.externalCompleter.enableFishCompleter ''
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
  };
}
