# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.handy;
    in
    {
      options.my.programs.handy = {
        enable = lib.mkEnableOption "Handy offline speech-to-text";
        autostart = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Start Handy on login.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          { home.packages = [ pkgs.handy ]; }

          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
            systemd.user.services.handy = lib.mkIf cfg.autostart {
              Unit = {
                Description = "Handy speech-to-text";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = lib.getExe pkgs.handy;
                Restart = "on-failure";
                RestartSec = 5;
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
          })

          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            launchd.agents.handy = lib.mkIf cfg.autostart {
              enable = true;
              config = {
                ProgramArguments = [ (lib.getExe pkgs.handy) ];
                RunAtLoad = true;
                # Relaunch only on a crash, not on a clean quit, so closing the
                # settings window does not immediately resurrect Handy.
                KeepAlive.SuccessfulExit = false;
              };
            };
          })
        ]
      );
    };

  nixosModule =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.programs.handy.enable = lib.mkEnableOption "Handy offline speech-to-text";

      config = lib.mkIf config.my.programs.handy.enable {
        # Handy reads /dev/input/event* via evdev for its global hotkey, which is
        # only readable by the input group; home-manager cannot grant it.
        users.users.${config.my.username}.extraGroups = [ "input" ];
      };
    };
in
{
  flake.modules.homeManager.handy = homeModule;
  flake.modules.nixos.handy = nixosModule;
}
