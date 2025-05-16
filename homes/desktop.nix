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
    ./shared/gpg
    ./shared/claude.nix
    ./shared/email.nix
    ./shared/weechat.nix
  ];

  my.services.copyq.enable = true;
}
