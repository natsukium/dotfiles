{ config, lib, ... }:
{
  imports = [
    ../../nixos/hardware/nvidia/driver.nix
    ../../nixos/hardware/nvidia/cuda.nix
    ../../nixos/hardware/nvidia/container.nix
  ];

  my.hardware.nvidia = {
    enable = true;

    cudaSupport.enable = true;

    containerSupport.enable = true;
  };
}
