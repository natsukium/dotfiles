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
      };
    };
}
