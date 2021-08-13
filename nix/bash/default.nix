{ pkgs, ... }:

{
  home.packages = with pkgs; [ bashInteractive_5 ];
  programs.bash = {
    enable = true;
    historyFile = "$XDG_CONFIG_HOME/bash/history";
    sessionVariables = {
      LANG = "ja_JP.UTF-8";
      LC_TYPE = "ja_JP.UTF-8";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_RUNTIME_DIR = "$HOME/.run";
    };
    shellAliases = {
      ls = "ls --color=auto";
      la = "ls -alF";
      ll = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
    };
    profileExtra = ''
      . $HOME/.nix-profile/etc/profile.d/nix.sh
      [[ -f $XDG_CONFIG_HOME/bash/environ ]] && . $XDG_CONFIG_HOME/bash/environ
    '';
    initExtra = ''
      stty stop undef  # Ctrl-s
      stty werase undef
      bind "\C-w":unix-filename-rubout  # Ctrl-w

      # colors
      if [ -x /usr/bin/dircolors ] && [ -f $HOME/.dircolors ]; then
        eval $(dircolors ~/.dircolors)
      fi

      # TMUX (from ArchWiki)
      if type tmux > /dev/null 2>&1; then
        # if no session is started, start a new session
        test -z $TMUX && tmux

        # when quitting tmux, try to attach
        while test -z $TMUX; do
          tmux attach || break
        done
      fi

      if type fish >/dev/null 2>&1; then
        exec fish
      fi
    '';
  };
}
