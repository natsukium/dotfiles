{
  pkgs,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    keybindings = import ./keybindings.nix;
    userSettings = import ./settings.nix {inherit lib;};
    userTasks = import ./tasks.nix;
  };
}
