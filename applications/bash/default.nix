{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [ bashInteractive ];
  programs.bash = {
    enable = true;
    historyFile = "$XDG_CONFIG_HOME/bash/history";
    enableCompletion = false;
    shellAliases = {
      l = "ls -CF";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
    };
    initExtra = ''
      stty stop undef  # Ctrl-s
      stty werase undef
      bind "\C-w":unix-filename-rubout  # Ctrl-w
    ''
    + lib.optionalString (!config.programs.kitty.enable) ''
      # TMUX (from ArchWiki)
      if type tmux > /dev/null 2>&1; then
        # if no session is started, start a new session
        test -z $TMUX && tmux

        # when quitting tmux, try to attach
        while test -z $TMUX; do
          tmux attach || break
        done
      fi
    '';
  };
}
