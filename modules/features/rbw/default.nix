{ ... }:
{
  flake.modules.homeManager.rbw =
    { config, pkgs, ... }:
    let
      cfg = config.programs.rbw;
    in
    {
      programs = {
        rbw = {
          enable = true;
          settings = {
            email = "tomoya.otabi@gmail.com";
            pinentry = pkgs.callPackage ../../../pkgs/pinentry-wrapper { };
          };
        };
      };

      my.programs.dotcli.plugins.rbw = {
        source = ./dotcli;
        settings = {
          rbw = pkgs.lib.getExe cfg.package;
          inherit (cfg.settings) email;
          baseUrl = cfg.settings.base_url or null;
          # rbw resolves this with the `directories` crate, not XDG, on macOS.
          cacheDir =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "${config.home.homeDirectory}/Library/Caches/rbw"
            else
              "${config.xdg.cacheHome}/rbw";
        };
      };
    };
}
