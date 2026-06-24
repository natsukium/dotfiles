{ inputs, ... }:
{
  imports = [
    inputs.self.modules.homeManager.emacs
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vscode
    ../applications/zotero
    ./shared/claude.nix
    ./shared/email.nix
    ./shared/gpg
    ./shared/weechat.nix
  ];

  my.programs.emacs.enable = true;

  my.services.copyq.enable = true;
  my.services.flameshot = {
    enable = true;
    settings.General = {
      startupLaunch = false;
      saveLastRegion = true;
    };
  };
}
