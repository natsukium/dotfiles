# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager.ssh =
    { config, lib, ... }:
    {
      options.my.programs.ssh.enable = lib.mkEnableOption "ssh client";

      config = lib.mkIf config.my.programs.ssh.enable {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
        };
      };
    };
}
