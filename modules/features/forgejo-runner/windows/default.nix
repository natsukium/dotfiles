# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
{
  flake.modules.nixos.windows-ci =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixvirt = inputs.nixvirt.lib;
      cfg = config.my.services.windows-ci;

      baseImage = "${cfg.stateDir}/base.qcow2";
      systemImage = "${cfg.stateDir}/system.qcow2";
      stateImage = "${cfg.stateDir}/state.qcow2";
      seedIso = "${cfg.stateDir}/seed.iso";
      # libvirt chowns every disk source it opens, which fails on the ntfs-3g mount
      # the ISO lives on, so the unit copies it in first.
      installIsoCopy = "${cfg.stateDir}/install.iso";

      guestMac = "52:54:00:c9:a0:e4";

      forgejoRunnerExe = pkgs.forgejo-runner.overrideAttrs (old: {
        env = old.env // {
          GOOS = "windows";
          GOARCH = "amd64";
          CGO_ENABLED = 0;
        };
        postInstall = "";
        doCheck = false;
        doInstallCheck = false;
      });

      spiceVdagent = pkgs.callPackage ./spice-vdagent.nix { };

      provisionScript = pkgs.replaceVars ./provision.ps1 {
        instanceUrl = cfg.url;
        runnerName = cfg.name;
        labels = lib.concatStringsSep "," cfg.labels;
      };

      payloadIso = pkgs.runCommand "windows-ci-payload.iso" { nativeBuildInputs = [ pkgs.xorriso ]; } ''
        mkdir payload
        cp ${forgejoRunnerExe}/bin/windows_amd64/runner.exe payload/forgejo-runner.exe
        cp ${provisionScript} payload/provision.ps1
        cp ${spiceVdagent} payload/spice-vdagent.msi
        xorriso -as mkisofs -J -r -V WINCI -o $out payload
      '';

      answerImage =
        pkgs.runCommand "windows-ci-answer.img"
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
        name = "windows-ci";
        uuid = "5cca2b52-0eb3-4a43-8ec8-778ebeaa3fcc";
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
        # null keeps the virtio framebuffer without 3D acceleration. A CI guest
        # renders nothing, so SPICE's OpenGL path only adds a failure mode.
        virtio_video = null;
        install_virtio = true;
      };

      domain = template // {
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
              device = "cdrom";
              driver = {
                name = "qemu";
                type = "raw";
              };
              source = {
                file = seedIso;
                startupPolicy = "optional";
              };
              target = {
                dev = "hdf";
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
      imports = [ inputs.nixvirt.nixosModules.default ];

      options.my.services.windows-ci = {
        enable = lib.mkEnableOption "a Windows guest registered as a Forgejo Actions runner";

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

        tokenFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to an environment file holding the registration token as
            `TOKEN=...`. The host supplies this, typically a secret-manager path, so
            the feature stays free of any secret-store assumption.
          '';
        };

        url = lib.mkOption {
          type = lib.types.str;
          default = "https://git.natsukium.com";
          description = "Forgejo instance the runner registers with.";
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "${config.networking.hostName}-windows";
          defaultText = lib.literalExpression ''"''${config.networking.hostName}-windows"'';
          description = "Name the runner registers under.";
        };

        labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "windows:host" ];
          description = ''
            Labels the runner advertises. Only `host` labels make sense here: a
            `docker` label would need Windows containers, which means Docker Desktop
            and its licence.
          '';
        };

        vcpu = lib.mkOption {
          type = lib.types.ints.positive;
          default = 6;
          description = "Threads given to the guest.";
        };

        memory = lib.mkOption {
          type = lib.types.ints.positive;
          default = 16;
          description = "Memory given to the guest, in GiB.";
        };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/libvirt/windows-ci";
          description = "Directory holding the guest's disk images and its seed disc.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = !cfg.installer || cfg.installerIso != null;
            message = "my.services.windows-ci.installerIso has to name an installation ISO while installer is on.";
          }
        ];

        virtualisation.libvirt = {
          enable = true;
          # Windows 11 refuses to install without a TPM 2.0.
          swtpm.enable = true;

          connections."qemu:///system" = {
            networks = [
              {
                definition = nixvirt.network.writeXML (
                  nixvirt.network.templates.bridge {
                    uuid = "4de77f71-1aba-49e0-a139-5454e752db84";
                    subnet_byte = 122;
                    dhcp_hosts = [
                      {
                        mac = guestMac;
                        name = "windows-ci";
                        ip = "192.168.122.10";
                      }
                    ];
                  }
                );
                active = true;
              }
            ];
            domains = [
              {
                # Setup only reads the answer file off a removable drive, and
                # NixVirt's schema has no attribute for that. Without the flag the disk
                # mounts and setup silently asks every question itself.
                definition = pkgs.runCommand "windows-ci.xml" { } ''
                  sed "s|<target dev='sda' bus='usb'/>|<target dev='sda' bus='usb' removable='on'/>|" \
                    ${nixvirt.domain.writeXML domain} > $out
                '';
                # Installing means starting and stopping the guest by hand, so the
                # activation script keeps out of it until the image is ready.
                active = if cfg.installer then null else true;
              }
            ];
          };
        };

        systemd.services.windows-ci-images = {
          description = "Provision disk images for the Windows CI guest";
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
          + lib.optionalString cfg.installer ''
            # Sizes rather than timestamps: a truncated download leaves a copy that
            # looks current.
            if [ "$(stat -c %s ${cfg.installerIso})" != "$(stat -c %s ${installIsoCopy} 2>/dev/null)" ]; then
              cp ${cfg.installerIso} ${installIsoCopy}
            fi
          '';
        };

        systemd.services.windows-ci-seed = {
          description = "Hand the Forgejo registration token to the Windows CI guest";
          wantedBy = [ "multi-user.target" ];
          before = [
            "libvirtd.service"
            "nixvirt.service"
          ];
          after = [ "windows-ci-images.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ pkgs.xorriso ];
          script = ''
            dir=$(mktemp -d)
            trap 'rm -rf "$dir"' EXIT

            sed -n 's/^TOKEN=//p' ${cfg.tokenFile} > "$dir/token.txt"

            xorriso -as mkisofs -J -r -V WINCISEED -o ${seedIso}.new "$dir"
            chmod 0400 ${seedIso}.new
            mv ${seedIso}.new ${seedIso}
          '';
        };

        virtualisation.libvirtd = {
          onShutdown = "shutdown";

          hooks.qemu = lib.optionalAttrs (!cfg.installer) {
            windows-ci = pkgs.writeShellScript "windows-ci-reset-system-disk" ''
              if [ "$1" != windows-ci ] || [ "$2" != prepare ] || [ "$3" != begin ]; then
                exit 0
              fi

              rm -f ${systemImage}
              ${pkgs.qemu-utils}/bin/qemu-img create -f qcow2 -F qcow2 -b ${baseImage} ${systemImage}
            '';
          };
        };

        environment.systemPackages = [
          pkgs.virt-manager
          pkgs.virt-viewer
        ];

        users.users.${config.my.username}.extraGroups = [ "libvirtd" ];
      };
    };
}
