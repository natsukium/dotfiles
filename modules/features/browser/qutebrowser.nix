{ ... }:
{
  flake.modules.homeManager.qutebrowser =
    { config, lib, ... }:
    {
      options.my.programs.qutebrowser.enable = lib.mkEnableOption "qutebrowser";

      config = lib.mkIf config.my.programs.qutebrowser.enable {
        programs.qutebrowser = {
          enable = true;
          settings = {
            content.blocking.method = "both";
            window.hide_decoration = true;
          };
        };
      };
    };
}
