{ pkgs, config, ... }:
{
  home.packages = [ pkgs.ghq ];
  programs.git.settings = {
    ghq.root = "${config.home.homeDirectory}/src/private";
  };
}
