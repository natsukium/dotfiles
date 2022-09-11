{pkgs, ...}: {
  programs.vim.enable = false; # if true, vim cannot read $XDG_CONFIG_HOME/vim/vimrc
  home.packages = [pkgs.vim];
  xdg.configFile."vim/vimrc".source = ./vimrc; # vimrc is read by vscode of Windows too
  programs.bash.profileExtra = ''
    export VIMINIT='source $XDG_CONFIG_HOME/vim/vimrc'
  '';
}
