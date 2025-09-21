{ config, lib, ... }:
let
  cfg = config.my.hardware.nvidia.containerSupport;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.my.hardware.nvidia.containerSupport = {
    enable = mkEnableOption "NVIDIA container toolkit for Docker/Podman";
  };

  config = mkIf cfg.enable {
    hardware.nvidia-container-toolkit.enable = true;

    assertions = [
      {
        assertion = config.my.hardware.nvidia.enable or false;
        message = "NVIDIA container toolkit requires NVIDIA hardware support to be enabled";
      }
    ];
  };
}
