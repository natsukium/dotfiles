{ ... }:
{
  flake.modules.homeManager.vscode =
    { config, lib, ... }:
    {
      options.my.programs.vscode.enable = lib.mkEnableOption "vscode";

      config = lib.mkIf config.my.programs.vscode.enable {
        programs.vscode = {
          enable = true;
          profiles.default = {
            keybindings = import ./keybindings.nix;
            userSettings = import ./settings.nix { inherit lib; };
            userTasks = import ./tasks.nix;
          };
        };
      };
    };
}
