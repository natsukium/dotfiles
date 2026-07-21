{ ... }:
{
  flake.modules.homeManager.skhd =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.skhd;
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
      };
    };
}
