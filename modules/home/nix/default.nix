# This file is auto-generated from configuration.org.
# Do not edit directly.

{ config, ... }:
{
  nix.settings.use-xdg-base-directories = config.xdg.enable;

  programs.git.ignores = [ "result" ];
}
