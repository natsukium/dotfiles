{ pkgs, ... }:
{
  programs.vim.enable = false; # if true, vim cannot read $XDG_CONFIG_HOME/vim/vimrc
  home.packages = [ pkgs.vim ];
  xdg.configFile."vim/vimrc".source = ./vimrc; # vimrc is read by vscode of Windows too
  home.sessionVariablesExtra = ''
    export VIMINIT='let $MYVIMRC = !has("nvim") ? "$XDG_CONFIG_HOME/vim/vimrc" : "$XDG_CONFIG_HOME/nvim/init.lua" | so $MYVIMRC'
  '';
}
