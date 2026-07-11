{ ... }:
{
  flake.modules.homeManager.nix =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.nix;
    in
    {
      options.my.nix.enable = lib.mkEnableOption "nix";

      config = lib.mkIf cfg.enable {
        nix.settings.use-xdg-base-directories = config.xdg.enable;

        programs.git.ignores = [ "result" ];
      };
    };
}
