{
  pkgs,
  lib,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isWsl;
in {
  programs.home-manager.enable = true;
  home = {
    stateVersion = "22.11";
  };

  imports =
    [
      ./alacritty
      ./bash
      ./bat
      ./fish
      ./ghq
      ./git
      ./nix
      ./python
      ./starship
      ./tmux
      ./vim
      ./misc
    ]
    ++ lib.optional (! isWsl) ./vscode;
}
