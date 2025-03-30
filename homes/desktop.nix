{ pkgs, ... }:
{
  imports = [
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../applications/vscode
    ./shared/email.nix
    ./shared/weechat.nix
  ];

  my.services.copyq.enable = true;
}
