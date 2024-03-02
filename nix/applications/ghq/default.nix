{ pkgs, config, ... }:
{
  home.packages = [ pkgs.ghq ];
  programs.git.extraConfig = {
    ghq.root = "${config.home.homeDirectory}/src/private";
    "ghq \"ssh://git@github.com-emu\"".root = "${config.home.homeDirectory}/src/work";
  };
}
