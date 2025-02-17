{ pkgs, ... }:
{
  imports = [
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../applications/vscode
    ./shared/email.nix
  ];

  services.copyq = {
    enable = true;
  };
}
