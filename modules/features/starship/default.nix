# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager.starship =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.programs.starship;
    in
    {
      options.my.programs.starship = {
        enable = lib.mkEnableOption "starship";

        enableFishAsyncPrompt = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          programs.starship = {
            enable = true;
            settings = builtins.fromTOML (builtins.readFile ./starship.toml);
          };
        })

        (lib.mkIf cfg.enableFishAsyncPrompt {
          # use my own script to ensure the execution order
          programs.starship.enableFishIntegration = lib.mkForce false;

          programs.fish.interactiveShellInit = ''
            if test "$TERM" != dumb
                ${lib.getExe config.programs.starship.package} init fish | source
                source ${./async_prompt.fish}
            end
          '';
        })
      ];
    };
}
