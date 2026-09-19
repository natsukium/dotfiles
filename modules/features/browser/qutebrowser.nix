{ ... }:
{
  flake.modules.homeManager.qutebrowser =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      appIdentity = pkgs.callPackage inputs.nix-mac-app-identity { };
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
