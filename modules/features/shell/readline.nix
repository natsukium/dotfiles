# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager.readline =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.my.programs.readline;
    in
    {
      options.my.programs.readline.enable = lib.mkEnableOption "readline";

      config = lib.mkIf cfg.enable {
        programs.readline = {
          enable = true;

          variables = {
            completion-ignore-case = true;
            bind-tty-special-chars = false;
          };

          bindings = {
            "\\C-w" = "unix-filename-rubout";
          };
        };
      };
    };
}
