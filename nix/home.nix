{pkgs, ...}: {
  programs.home-manager.enable = true;
  home = {
    stateVersion = "22.11";
  };

  imports = [
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
    ./vscode
    ./misc
  ];
}
