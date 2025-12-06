{ config, ... }:
{
  nix.settings.use-xdg-base-directories = config.xdg.enable;

  programs.git.ignores = [ "result" ];
}
