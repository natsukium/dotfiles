{ pkgs, ... }:
{
  imports = [
    ../applications/alacritty
    ../applications/emacs
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../applications/vscode
    ../applications/zen-browser
    ../applications/zotero
    ./shared/claude.nix
    ./shared/email.nix
    ./shared/gpg
    ./shared/weechat.nix
  ];

  my.services.copyq.enable = true;
}
