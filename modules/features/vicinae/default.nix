# This file is auto-generated from configuration.org.
# Do not edit directly.

# Requires: inputs.vicinae, inputs.vicinae-extensions
{ inputs, ... }:
{
  flake.modules.homeManager.vicinae =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      options.my.programs.vicinae.enable = lib.mkEnableOption "vicinae launcher";

      config = lib.mkIf config.my.programs.vicinae.enable {
        programs.vicinae = {
          enable = true;
          systemd.enable = true;
          launchd = {
            enable = true;
            environment.PATH = "${lib.makeBinPath [ pkgs.rbw ]}:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          extensions = [
            inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.bitwarden
          ];
          settings = {
            keybinding = "emacs";
            theme.dark.name = "nord";
          };
        };
      };
    };
}
