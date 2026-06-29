# This file is auto-generated from configuration.org.
# Do not edit directly.

# Requires: inputs.vicinae
{ inputs, ... }:
{
  flake.modules.homeManager.vicinae =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      options.my.programs.vicinae.enable = lib.mkEnableOption "vicinae launcher";

      config = lib.mkIf config.my.programs.vicinae.enable {
        programs.vicinae = {
          enable = true;
          systemd.enable = true;
          launchd.enable = true;
        };
      };
    };
}
