{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkIf
    mkOption
    types
    ;
  cfg = config.ext.hydra;
in
{
  options = {
    ext.hydra = {
      localBuilder = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };
        systems = mkOption {
          type = types.listOf types.str;
          default = [ pkgs.stdenv.hostPlatform.system ];
          example = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        };
        maxJobs = mkOption {
          type = types.int;
          default = config.nix.settings.max-jobs;
        };
        speedFactor = mkOption {
          type = types.int;
          default = 1;
        };
        supportedFeatures = mkOption {
          type = types.listOf types.str;
          default = config.nix.settings.system-features;
          example = [ "kvm" ];
        };
        mandatoryFeatures = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "kvm" ];
        };
      };
    };
  };

  config = mkIf config.services.hydra.enable {
    services.hydra.buildMachinesFiles =
      let
        features = xs: if xs == [ ] then "-" else concatStringsSep "," xs;
      in
      lib.optionals cfg.localBuilder.enable [
        (pkgs.writeText "local" ''
          localhost ${concatStringsSep "," cfg.localBuilder.systems} - ${toString cfg.localBuilder.maxJobs} ${toString cfg.localBuilder.speedFactor} ${
            features (cfg.localBuilder.supportedFeatures ++ cfg.localBuilder.mandatoryFeatures)
          } ${features (cfg.localBuilder.mandatoryFeatures)} -
        '')
      ];
  };
}
