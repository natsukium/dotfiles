{ config, lib, ... }:
let
  cfg = config.my.hardware.nvidia.cudaSupport;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.my.hardware.nvidia.cudaSupport = {
    enable = mkEnableOption "CUDA support for GPU computing";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.cudaSupport = true;

    # CUDA requires NVIDIA drivers to be enabled
    assertions = [
      {
        assertion = config.my.hardware.nvidia.enable or false;
        message = "CUDA support requires NVIDIA hardware support to be enabled";
      }
    ];
  };
}
