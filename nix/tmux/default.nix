{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-j";
    clock24 = true;
    historyLimit = 5000;
    plugins = with pkgs.tmuxPlugins; [
      copycat
      nord
      open
      pain-control
      prefix-highlight
      sensible
      yank
    ];
    extraConfig = ''
      bind-key r source-file $XDG_CONFIG_HOME/tmux/tmux.conf
      setw -g mouse on
      set -g status-position top
      set -g @open-S 'https://www.google.com/search?q='
    '';
  };
}
