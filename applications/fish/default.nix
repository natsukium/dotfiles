{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      bind \cs zi
      # set done's variable
      set -U __done_min_cmd_duration 15000

      # set environment variable for pinentry
      if test "$SSH_CONNECTION" != ""
        set -x PINENTRY_USER_DATA "USE_CURSES"
      end

      # extra abbrs
      abbr -a L --position anywhere --set-cursor "% | less"
      abbr -a !! --position anywhere --function _abbr_last_history_item
      abbr -a extract_tar_gz --position command --regex ".+\.tar\.gz" --function _abbr_extract_tar_gz
      abbr -a dotdot --regex '^\.\.+$' --function _abbr_multicd

      ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source
    '';

    shellAbbrs = {
      # spellchecker:off
      l = "ls";

      # for Nix
      "--sxl" = {
        position = "anywhere";
        expansion =
          "--system x86_64-linux"
          + pkgs.lib.optionalString (
            pkgs.stdenv.hostPlatform.isDarwin || pkgs.stdenv.hostPlatform.isAarch64
          ) " -j0";
      };
      "--sal" = {
        position = "anywhere";
        expansion =
          "--system aarch64-linux"
          + pkgs.lib.optionalString (
            pkgs.stdenv.hostPlatform.isDarwin || pkgs.stdenv.hostPlatform.isx86_64
          ) " -j0";
      };
      "--sxd" = {
        position = "anywhere";
        expansion =
          "--system x86_64-darwin" + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux " -j0";
      };
      "--sad" = {
        position = "anywhere";
        expansion =
          "--system aarch64-darwin" + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux " -j0";
      };
      # spellchecker:on
    };

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
}
