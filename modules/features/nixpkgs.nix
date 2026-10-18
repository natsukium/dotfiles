# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  module =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.nixpkgs;
    in
    {
      options.my.nixpkgs = {
        enable = lib.mkEnableOption "Nixpkgs configuration";

        allowUnfree = lib.mkOption {
          default = true;
          example = false;
          description = "Whether to allow unfree packages.";
          type = lib.types.bool;
        };
      };

      config = lib.mkIf cfg.enable {
        nixpkgs = {
          config.allowUnfree = cfg.allowUnfree;
          config.permittedInsecurePackages = [
            "firefox-esr-140-bin-unwrapped-140.17.0esr"
          ];
        };
      };
    };
in
{
  flake.modules.nixos.nixpkgs = module;
  flake.modules.darwin.nixpkgs = module;
}
