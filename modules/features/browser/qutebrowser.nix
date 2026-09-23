{ ... }:
{
  flake.modules.homeManager.qutebrowser =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.lib) appIdentity;
    in
    {
      options.my.programs.qutebrowser.enable = lib.mkEnableOption "qutebrowser";

      config = lib.mkIf config.my.programs.qutebrowser.enable {
        programs.qutebrowser = {
          enable = true;
          package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (appIdentity.stabilizeApp pkgs.qutebrowser);
          settings = {
            content.blocking.method = "both";
            window.hide_decoration = true;
          };
        };
      };
    };
}
