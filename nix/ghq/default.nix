{ pkgs, ... }:
{
  home.packages = [ pkgs.ghq ];
  programs.git.extraConfig = {
    ghq.root = "~/src/private";
    "ghq \"ssh://git@github.com-emu\"".root = "~/src/work";
  };
}
