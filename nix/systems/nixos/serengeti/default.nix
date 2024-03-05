{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "serengeti";
  };

  nix.settings = {
    max-jobs = 2;
  };
}
