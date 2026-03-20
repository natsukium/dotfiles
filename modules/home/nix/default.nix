# This file is auto-generated from docs/nix.org.
# Do not edit directly.

{ config, ... }:
{
  nix.settings.use-xdg-base-directories = config.xdg.enable;

  programs.git.ignores = [ "result" ];
}
