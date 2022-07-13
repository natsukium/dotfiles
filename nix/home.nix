{ pkgs, ... }: {
  programs.home-manager.enable = true;
  home = {
    username = "$USER";
    homeDirectory = /. + "$HOME";
    stateVersion = "22.11";
  };

  imports = [
    ./alacritty
    ./bash
    ./bat
    ./fish
    ./ghq
    ./git
    ./python
    ./starship
    ./tmux
    ./vim
    ./misc
  ];
}
