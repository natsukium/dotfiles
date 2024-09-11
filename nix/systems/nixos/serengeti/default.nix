{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../services/attic
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
  ];

  inherit (import ./disko-config.nix { disks = [ "/dev/sda" ]; }) disko;

  ext.btrfs = {
    enable = true;
    wipeRootOnBoot = true;
  };

  environment.persistence."/persistent" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };

  fileSystems."/persistent".neededForBoot = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # https://github.com/nix-community/nixos-anywhere/issues/178
  security.sudo.wheelNeedsPassword = false;

  networking = {
    hostName = "serengeti";
  };

  services.cloudflared.enable = true;

  nix.settings = {
    max-jobs = 2;
  };
}
