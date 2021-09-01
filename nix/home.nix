{ pkgs, ... }: {
  programs.home-manager.enable = true;
  home = {
    username = "$USER";
    homeDirectory = /. + "$HOME";
    stateVersion = "21.05";
  };

  imports = [
    ./alacritty
    ./bash
    ./bat
    ./fish
    ./git
    ./python
    ./starship
    ./tmux
    ./vim
    ./misc
  ];
}
