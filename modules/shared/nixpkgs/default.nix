{ config, lib, ... }:
let
  cfg = config.my.nixpkgs;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options.my.nixpkgs = {
    enable = mkEnableOption "Nixpkgs configuration";

    allowUnfree = mkOption {
      default = true;
      example = false;
      description = "Whether to allow unfree packages.";
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    nixpkgs = {
      config.allowUnfree = cfg.allowUnfree;
    };
  };
}
