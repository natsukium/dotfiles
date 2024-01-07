{ pkgs, ... }: { xdg.configFile."npm/npmrc".source = ./npmrc; }
