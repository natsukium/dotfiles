{ pkgs, ... }:
{
  imports = [ ../common.nix ];

  nix.settings = {
    max-jobs = 4;
  };

  programs.zsh.enable = true;
}
