{ pkgs, ... }:
{
  imports = [
    ../applications/emacs
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vscode
    ../applications/zotero
    ../modules/home/coding-agents/claude-desktop
    ../modules/home/email
    ../modules/home/security/gpg
    ../modules/home/communication/weechat
  ];

  my.services.copyq.enable = true;
  my.services.flameshot = {
    enable = true;
    settings.General = {
      startupLaunch = false;
      saveLastRegion = true;
    };
  };
}
