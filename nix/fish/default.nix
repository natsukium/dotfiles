{pkgs, ...}: let
  cfgSource = path: {
    name = "fish/" + path;
    value = {source = ./. + "/${path}";};
  };
  cfgSources = paths: builtins.listToAttrs (map cfgSource paths);
in {
  programs.fish = {
    enable = true;
    shellInit = pkgs.lib.mkIf pkgs.stdenv.isDarwin ''
      for p in /nix/var/nix/profiles/default/bin /run/current-system/sw/bin /etc/profiles/per-user/(users)/bin /Users/(users)/.nix-profile/bin
        if not contains $p $fish_user_paths
          set -g fish_user_paths $p $fish_user_paths
        end
      end
    '';
    interactiveShellInit = ''
      bind \cs zi
      # set done's variable
      set -U __done_min_cmd_duration 15000

      # extra abbrs
      abbr -a L --position anywhere --set-cursor "% | less"
      abbr -a !! --position anywhere --function _abbr_last_history_item
      abbr -a extract_tar_gz --position command --regex ".+\.tar\.gz" --function _abbr_extract_tar_gz
      abbr -a dotdot --regex '^\.\.+$' --function _abbr_multicd
    '';

    functions = {
      _abbr_last_history_item = "echo $history[1]";
      _abbr_extract_tar_gz = "echo tar avfx $argv";
      _abbr_multicd = "echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)";
    };
    plugins = [
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
    ];
  };
  xdg.configFile = cfgSources [
    "functions/bash.fish"
    "functions/bw-session-helper.fish"
    "functions/l.fish"
    "functions/lld.fish"
    "functions/nix-shell.fish"
    "functions/pskill.fish"
    "functions/su.fish"
  ];
}
