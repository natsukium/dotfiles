{ ... }:
{
  flake.modules.nixos.nvidia =
    { config, lib, ... }:
    {
      options.my.devices.nvidia.enable = lib.mkEnableOption "the proprietary NVIDIA driver";

      config = lib.mkIf config.my.devices.nvidia.enable {
        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        hardware.nvidia = {
          powerManagement.enable = true;
          # open kernel module is too unstable and often incompatible with the runtime
          open = false;
        };

        # A loaded nvidia module cannot be replaced while the GPU is in use, so a live
        # switch to a new driver leaves the old module under new userspace libraries.
        # NVML then refuses with "Driver/library version mismatch" and every CUDA and
        # GL client breaks until reboot. A driver change now only applies at boot.
        system.switch.inhibitors.nvidia = config.hardware.nvidia.package.version;
      };
    };
}
