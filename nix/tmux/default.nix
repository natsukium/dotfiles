{pkgs, ...}: {
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
      bind g popup -d '#{pane_current_path}' -w90% -h90% -E ${pkgs.gitui}/bin/gitui
    '';
  };
}
