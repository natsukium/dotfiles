{ ... }:
{
  flake.modules.homeManager.calibre =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.programs.calibre.enable = lib.mkEnableOption "calibre";

      config = lib.mkIf config.my.programs.calibre.enable {
        programs.calibre.enable = true;
      };
    };
}
