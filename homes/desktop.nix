{ inputs, ... }:
{
  imports = [
    inputs.self.modules.homeManager.emacs
    inputs.self.modules.homeManager.vicinae
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
  my.programs.vicinae.enable = true;

  my.services.copyq.enable = true;
  my.services.flameshot = {
    enable = true;
    settings.General = {
      startupLaunch = false;
      saveLastRegion = true;
    };
  };
}
