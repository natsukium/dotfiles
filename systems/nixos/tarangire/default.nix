{ inputs, config, ... }:
{
  imports = [
    ../../../modules/profiles/nixos/base.nix
    ../../server.nix
    ../../shared/hercules-ci/agent.nix
    ../common.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  inherit (import ./disko-config.nix { disks = [ "/dev/nvme0n1" ]; }) disko;

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

  # workaround for https://github.com/NixOS/nixpkgs/pull/351151#issuecomment-2440083015
  boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

  fileSystems."/persistent".neededForBoot = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "tarangire";
  };

  nix.settings = {
    max-jobs = 12;
  };
}
