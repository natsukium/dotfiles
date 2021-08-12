{ pkgs, ... }: {
  programs.home-manager.enable = true;
  home = {
    username = "$USER";
    homeDirectory = "/Users/$USER";
    stateVersion = "21.05";
  };

  imports = [ ./git ./bash ./tmux ];
}
