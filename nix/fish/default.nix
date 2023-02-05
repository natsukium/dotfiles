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
      # Set color theme
      set -U fish_color_normal normal
      set -U fish_color_command 81a1c1
      set -U fish_color_quote a3be8c
      set -U fish_color_redirection b48ead
      set -U fish_color_end 88c0d0
      set -U fish_color_error ebcb8b
      set -U fish_color_param eceff4
      set -U fish_color_comment 434c5e
      set -U fish_color_match --background=brblue
      set -U fish_color_selection white --bold --background=brblack
      set -U fish_color_search_match bryellow --background=brblack
      set -U fish_color_history_current --bold
      set -U fish_color_operator 00a6b2
      set -U fish_color_escape 00a6b2
      set -U fish_color_cwd green
      set -U fish_color_cwd_root red
      set -U fish_color_valid_path --underline
      set -U fish_color_autosuggestion 4c566a
      set -U fish_color_user brgreen
      set -U fish_color_host normal
      set -U fish_color_cancel -r
      set -U fish_pager_color_completion normal
      set -U fish_pager_color_description B3A06D yellow
      set -U fish_pager_color_prefix white --bold --underline
      set -U fish_pager_color_progress brwhite --background=cyan
    '';
    plugins = [
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
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
  home.packages = with pkgs; [
    fishPlugins.fzf-fish
  ];
}
