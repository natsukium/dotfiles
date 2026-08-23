{ ... }:
{
  my.programs.kitty.enable = true;
  my.programs.qutebrowser.enable = true;
  my.programs.vscode.enable = true;
  my.programs.zotero.enable = true;

  imports = [
    ./shared/email.nix
    ./shared/gpg
    ./shared/weechat.nix
  ];

  my.programs.emacs.enable = true;
  my.programs.felis.enable = true;
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
