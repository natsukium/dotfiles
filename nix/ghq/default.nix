{ pkgs, ... }:

{
  home.packages = [ pkgs.ghq ];
  programs.git.extraConfig = {
    ghq.root = "~/src/private";
    "ghq \"ssh://git@gitlab.com/exwzd\"".root = "~/src/work";
    "ghq \"ssh://git@gitlab.com/tomoya.matsumoto\"".root = "~/src/work";
  };
}
