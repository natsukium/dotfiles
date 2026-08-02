# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager.ente-auth =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.ente-auth;
    in
    {
      options.my.programs.ente-auth = {
        enable = lib.mkEnableOption "Ente Auth";
        package = lib.mkOption {
          type = lib.types.package;
          # nixpkgs marks ente-auth as Linux-only, so darwin falls back to the
          # upstream cask exposed by the brew-nix overlay.
          default = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.brewCasks.ente-auth else pkgs.ente-auth;
          defaultText = lib.literalExpression "pkgs.ente-auth";
          description = "The Ente Auth package to install.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];
      };
    };
}
