{ inputs, config, ... }:
{
  imports = [
    ../../../modules/profiles/nixos/base.nix
    ../../server.nix
    ../../shared/hercules-ci/agent.nix
    ../common.nix
    ../services/attic
    ./hardware-configuration.nix
    inputs.impermanence.nixosModules.impermanence
  ];

  inherit (import ./disko-config.nix { disks = [ "/dev/sda" ]; }) disko;

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

  # https://github.com/nix-community/nixos-anywhere/issues/178
  security.sudo.wheelNeedsPassword = false;

  networking = {
    hostName = "serengeti";
  };

  services.cloudflared = {
    enable = true;
    certificateFile = config.sops.secrets.cloudflared-tunnel-cert.path;
  };
  sops.secrets.cloudflared-tunnel-cert = { };

  nix.settings = {
    max-jobs = 2;
  };
}
