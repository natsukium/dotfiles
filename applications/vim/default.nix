{ pkgs, ... }:
{
  programs.vim.enable = true;
  xdg.configFile."vim/vimrc".source = ./vimrc; # vimrc is read by vscode of Windows too
}
