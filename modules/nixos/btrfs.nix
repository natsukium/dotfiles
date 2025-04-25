{ config, lib, ... }:
with lib;
let
  cfg = config.my.services.btrfs;
in
{
  options = with types; {
    my.services.btrfs = {
      enable = mkOption {
        type = lib.types.bool;
        default = if config.fileSystems ? "/" then config.fileSystems."/".fsType == "btrfs" else false;
        description = "Whether to enable my btrfs services.";
      };

      wipeRootOnBoot = mkOption {
        type = bool;
        default = config.environment ? persistence;
        description = ''
          Wipe the root volume on boot.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.btrfs.autoScrub.enable = true;
    }

    (mkIf cfg.wipeRootOnBoot {
      # https://discourse.nixos.org/t/impermanence-vs-systemd-initrd-w-tpm-unlocking/25167
      # https://guekka.github.io/nixos-server-1/
      boot.initrd.systemd.enable = true;
      boot.initrd.systemd.services.roolback =
        let
          # TODO: allow user to select device
          device = "/dev/disk/by-partlabel/disk-main-root";
          # unitName should be like "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device"
          unitName =
            lib.removePrefix "-" (
              lib.replaceStrings
                [
                  "-"
                  "/"
                ]
                [
                  "\\x2d"
                  "-"
                ]
                device
            )
            + ".device";
        in
        {
          description = "Rollback BTRFS root subvolume";
          wantedBy = [ "initrd.target" ];
          requires = [ unitName ];
          after = [ unitName ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir /btrfs_tmp
            mount ${device} /btrfs_tmp
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
    })
  ]);
}
