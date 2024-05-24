{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
  ];

  inherit (import ./disko-config.nix { disks = [ "/dev/sda" ]; }) disko;

  # https://discourse.nixos.org/t/impermanence-vs-systemd-initrd-w-tpm-unlocking/25167
  # https://guekka.github.io/nixos-server-1/
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.roolback = {
    description = "Rollback BTRFS root subvolume";
    wantedBy = [ "initrd.target" ];
    requires = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device" ];
    after = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-partlabel/disk-main-root /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              echo "removing $i ..."
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      echo "recreate root ..."
      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
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

  services.btrfs.autoScrub.enable = true;

  networking = {
    hostName = "serengeti";
  };

  nix.settings = {
    max-jobs = 2;
  };
}
