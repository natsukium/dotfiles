{ pkgs, ... }:
{
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

    shellAbbrs = {
      l = "ls";
    };

    functions = {
      bash = {
        body = ''
          set length (count $argv)
          if test $length -gt 1 >/dev/null
              command bash --norc -c "$argv"
          else if test $length -eq 1 >/dev/null
              command bash --norc $argv
          else
              USEBASH=true command bash
          end
        '';
      };
      nix-shell = {
        description = "A wrapper of nix-shell for fish called from .bashrc";
        body = ''
          argparse --ignore-unknown 'command=' 'run=' -- $argv
          or return

          set -lq _flag_run
          or set -l _flag_run "fish"

          if set -lq _flag_command
              command nix-shell $argv --run $_flag_run --command $_flag_command
          else
              command nix-shell $argv --run $_flag_run
          end
        '';
      };
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
}
