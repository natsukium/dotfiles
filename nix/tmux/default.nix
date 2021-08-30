{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-j";
    clock24 = true;
    historyLimit = 50000;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
      copycat
      nord
      open
      pain-control
      prefix-highlight
      resurrect
      sensible
      yank
    ];
    extraConfig = ''
      setw -g mouse on
      set -g status-position top
    '';
  };
}
