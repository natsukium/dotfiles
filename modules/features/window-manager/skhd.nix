{ ... }:
{
  flake.modules.homeManager.skhd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.skhd;
      inherit (config.lib) appIdentity;

      # macOS identifies a bare executable by absolute path, so skhd's
      # Accessibility grant would die with the store path on every rebuild.
      # Everything launched from a hotkey inherits skhd as its responsible
      # process, so that one grant carries the rest with it.
      app = appIdentity.mkAppBundle {
        package = config.services.skhd.package;
        identifier = "com.koekeishiya.skhd";
      };
    in
    {
      options.my.services.skhd.enable = lib.mkEnableOption "skhd hotkey daemon";

      config = lib.mkIf cfg.enable {
        services.skhd = {
          enable = true;
          config = ''
            cmd - return : ${lib.getExe config.programs.felis.package}
          '';
        };

        launchd.agents.skhd.config.ProgramArguments = lib.mkForce [ (lib.getExe app) ];
      };
    };
}
