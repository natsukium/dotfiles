# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
{
  flake.modules.nixos.windows-vm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixvirt = inputs.nixvirt.lib;
      cfg = config.my.services.windows-vm;

      baseImage = cfg.baseImage;
      systemImage = "${cfg.stateDir}/system.qcow2";
      stateImage = "${cfg.stateDir}/state.qcow2";
      # libvirt chowns every disk source it opens, which fails on the ntfs-3g mount
      # the ISO lives on, so the unit copies it in first.
      installIsoCopy = "${cfg.stateDir}/install.iso";

      guestMac = "52:54:00:c9:a0:e4";

      spiceVdagent = pkgs.callPackage ./spice-vdagent.nix { };

      payloadIso = pkgs.runCommand "windows-vm-payload.iso" { nativeBuildInputs = [ pkgs.xorriso ]; } ''
        mkdir payload
        cp ${./provision.ps1} payload/provision.ps1
        cp ${./bootstrap.ps1} payload/bootstrap.ps1
        cp ${./share.ps1} payload/share.ps1
        cp ${spiceVdagent} payload/spice-vdagent.msi
        xorriso -as mkisofs -J -r -V WINVM -o $out payload
      '';

      answerImage =
        pkgs.runCommand "windows-vm-answer.img"
          {
            nativeBuildInputs = [
              pkgs.dosfstools
              pkgs.mtools
              pkgs.util-linux
            ];
          }
          ''
            truncate -s 16M image
            printf 'label: dos\n2048,,c,*\n' | sfdisk image
            mkfs.fat --offset 2048 -F 16 -n ANSWER image
            sed '/<settings pass="windowsPE">/,/<\/settings>/d' ${./autounattend.xml} > unattend.xml
            mcopy -i image@@1M ${./autounattend.xml} ::/autounattend.xml
            mcopy -i image@@1M unattend.xml ::/unattend.xml
            mv image $out
          '';

      template = nixvirt.domain.templates.windows {
        name = "windows";
        uuid = "e68fc8b5-3214-4c79-8469-62c76aec521b";
        vcpu = {
          count = cfg.vcpu;
        };
        memory = {
          count = cfg.memory;
          unit = "GiB";
        };
        storage_vol = if cfg.installer then baseImage else systemImage;
        backing_vol = if cfg.installer then null else baseImage;
        install_vol = if cfg.installer then installIsoCopy else null;
        nvram_path = "${cfg.stateDir}/nvram.fd";
        net_iface_mac = guestMac;
        # The fallback model is an rtl8139, which Windows has no driver for. NetKVM
        # comes off the virtio disc while WinPE is up.
        virtio_net = true;
        virtio_drive = true;
        # null keeps the virtio framebuffer without 3D acceleration. SPICE's OpenGL
        # path only adds a failure mode, and nothing here draws hard enough to miss it.
        virtio_video = null;
        install_virtio = true;
      };

      domain =
        template
        // lib.optionalAttrs (cfg.sharedDirectories != [ ]) {
          # virtiofsd reads the guest's memory rather than copying through qemu, so
          # qemu has to hold it somewhere another process can map.
          memoryBacking.access.mode = "shared";
        }
        // {
          # Per-device boot order rather than an os-level `boot dev='cdrom'`, which
          # with three CDROMs attached drops OVMF into its boot manager on every start.
          # libvirt rejects the two forms together.
          os = template.os // {
            boot = [ ];
          };

          devices = template.devices // {
            memballoon = {
              model = "virtio";
              freePageReporting = true;
            };

            # NixOS links no virtiofsd where libvirt goes looking for one, so the
            # domain names the binary itself.
            filesystem = map (dir: {
              type = "mount";
              accessmode = "passthrough";
              driver.type = "virtiofs";
              binary.path = "${pkgs.virtiofsd}/bin/virtiofsd";
              source.dir = dir;
              target.dir = builtins.baseNameOf dir;
            }) cfg.sharedDirectories;

            # Without the guest agent channel `virsh shutdown` reaches nothing and the
            # guest can only be killed.
            channel = template.devices.channel ++ [
              {
                type = "unix";
                target = {
                  type = "virtio";
                  name = "org.qemu.guest_agent.0";
                };
              }
            ];

            disk = [
              # The template's own three, in order: system disk, installer CDROM,
              # virtio-win CDROM.
              (
                builtins.elemAt template.devices.disk 0
                // {
                  boot.order = if cfg.installer then 2 else 1;
                }
              )
              (builtins.elemAt template.devices.disk 1 // lib.optionalAttrs cfg.installer { boot.order = 1; })
              (builtins.elemAt template.devices.disk 2)
              {
                type = "file";
                device = "cdrom";
                driver = {
                  name = "qemu";
                  type = "raw";
                };
                source.file = "${payloadIso}";
                target = {
                  dev = "hde";
                  bus = "sata";
                };
                readonly = true;
              }
              {
                type = "file";
                device = "disk";
                driver = {
                  name = "qemu";
                  type = "qcow2";
                  cache = "none";
                  discard = "unmap";
                };
                source.file = stateImage;
                target = {
                  dev = "vdb";
                  bus = "virtio";
                };
              }
            ]
            ++ lib.optional cfg.installer {
              type = "file";
              device = "disk";
              driver = {
                name = "qemu";
                type = "raw";
              };
              source.file = "${answerImage}";
              target = {
                dev = "sda";
                bus = "usb";
              };
              # The image sits in the store, and qemu opens a writable disk for writing,
              # which the store refuses. Setup only ever reads the answer file.
              readonly = true;
            };
          };
        };
    in
    {
      options.my.services.windows-vm = {
        enable = lib.mkEnableOption "a Windows guest and the golden image behind it";

        installer = lib.mkEnableOption ''
          the install shape, where the guest writes into the golden image itself
        '';

        installerIso = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Windows installation ISO on the host, read only while
            {option}`installer` is on.
          '';
        };

        vcpu = lib.mkOption {
          type = lib.types.ints.positive;
          default = 4;
          description = "Threads given to the guest.";
        };

        memory = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8;
          description = "Memory given to the guest, in GiB.";
        };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/libvirt/windows";
          description = "Directory holding the golden image and the guest's disks.";
        };

        sharedDirectories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "/data" ];
          description = ''
            Host directories the guest reaches over virtiofs, read and write, one mount
            each, tagged with the directory's own name.
          '';
        };

        baseImage = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${cfg.stateDir}/base.qcow2";
          description = "The golden image, for guests that stack an overlay on it.";
        };

        payloadIso = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = payloadIso;
          description = ''
            The disc carrying {file}`provision.ps1`, which every guest needs to set its
            own D: up.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = !cfg.installer || cfg.installerIso != null;
            message = "my.services.windows-vm.installerIso has to name an installation ISO while installer is on.";
          }
        ];

        my.virtualisation.libvirt = {
          enable = true;
          dhcpHosts = [
            {
              mac = guestMac;
              name = "windows";
              ip = "192.168.122.10";
            }
          ];
        };

        virtualisation.libvirt.connections."qemu:///system".domains = [
          {
            # Setup only reads the answer file off a removable drive, and NixVirt's
            # schema has no attribute for that. Without the flag the disk mounts and
            # setup silently asks every question itself.
            definition = pkgs.runCommand "windows.xml" { } ''
              sed "s|<target dev='sda' bus='usb'/>|<target dev='sda' bus='usb' removable='on'/>|" \
                ${nixvirt.domain.writeXML domain} > $out
            '';
            active = null;
          }
        ];

        systemd.services.windows-vm-images = {
          description = "Provision disk images for the Windows guest";
          wantedBy = [ "multi-user.target" ];
          before = [
            "libvirtd.service"
            "nixvirt.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Copying an 8 GiB ISO runs well past the 90 second default.
            TimeoutStartSec = "30min";
          };
          path = [
            pkgs.e2fsprogs
            pkgs.qemu-utils
          ];
          script = ''
            mkdir -p ${cfg.stateDir}
            # btrfs doing copy-on-write on top of qcow2's own fragments the image
            # badly. The attribute is inherited, so it has to land before the images do.
            chattr +C ${cfg.stateDir} || true
            test -e ${baseImage} || qemu-img create -f qcow2 ${baseImage} 80G
            test -e ${stateImage} || qemu-img create -f qcow2 ${stateImage} 32G
          ''
          + lib.optionalString (!cfg.installer) ''
            if [ -e ${baseImage} ] && [ ! -e ${systemImage} ]; then
              qemu-img create -f qcow2 -F qcow2 -b ${baseImage} ${systemImage}
            fi
          ''
          + lib.optionalString cfg.installer ''
            # Sizes rather than timestamps: a truncated download leaves a copy that
            # looks current.
            if [ "$(stat -c %s ${cfg.installerIso})" != "$(stat -c %s ${installIsoCopy} 2>/dev/null)" ]; then
              cp ${cfg.installerIso} ${installIsoCopy}
            fi
          '';
        };
      };
    };
}
