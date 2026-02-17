{ pkgs, ... }:
{
  imports = [
    ../applications/emacs
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../applications/vscode
    ../applications/zotero
    ./shared/claude.nix
    ./shared/email.nix
    ./shared/gpg
    ./shared/weechat.nix
  ];

  my.services.copyq.enable = true;
}
