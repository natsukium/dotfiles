{ config, lib, ... }:
let
  cfg = config.my.hardware.nvidia;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options.my.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA GPU driver support";

    package = mkOption {
      type = types.package;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
      defaultText = lib.literalExpression "config.boot.kernelPackages.nvidiaPackages.stable";
      description = "The NVIDIA driver package to use";
    };

    openKernel = mkOption {
      type = types.bool;
      default = false;
      description = "Use the open-source NVIDIA kernel module";
    };

    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NVIDIA GPU power management";
      };
    };

    modesetting = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable kernel modesetting for NVIDIA";
      };
    };

    nvidiaSettings = mkOption {
      type = types.bool;
      default = true;
      description = "Enable nvidia-settings GUI tool";
    };
  };

  config = mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      package = cfg.package;
      open = cfg.openKernel;
      modesetting.enable = cfg.modesetting.enable;
      powerManagement.enable = cfg.powerManagement.enable;
      nvidiaSettings = cfg.nvidiaSettings;
    };
  };
}
