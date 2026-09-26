# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
{
  flake.modules.nixos.forgejo-runner-windows =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixvirt = inputs.nixvirt.lib;
      runner = config.my.services.forgejo-runner;
      cfg = runner.windows;
      windows = config.my.services.windows-vm;

      baseImage = windows.baseImage;
      systemImage = "${windows.stateDir}/ci-system.qcow2";
      stateImage = "${windows.stateDir}/ci-state.qcow2";
      nvram = "${windows.stateDir}/ci-nvram.fd";
      seedIso = "${windows.stateDir}/ci-seed.iso";

      guestMac = "52:54:00:c9:a0:e5";

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

      registerScript = pkgs.replaceVars ./register.ps1 {
        instanceUrl = runner.url;
        runnerName = cfg.name;
        labels = lib.concatStringsSep "," cfg.labels;
      };

      runnerIso = pkgs.runCommand "windows-ci-runner.iso" { nativeBuildInputs = [ pkgs.xorriso ]; } ''
        mkdir runner
        cp ${forgejoRunnerExe}/bin/windows_amd64/runner.exe runner/forgejo-runner.exe
        cp ${registerScript} runner/register.ps1
        cp ${./bootstrap.ps1} runner/bootstrap.ps1
        xorriso -as mkisofs -J -r -V WINRUN -o $out runner
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
        storage_vol = systemImage;
        backing_vol = baseImage;
        nvram_path = nvram;
        net_iface_mac = guestMac;
        virtio_net = true;
        virtio_drive = true;
        # null keeps the virtio framebuffer without 3D acceleration. A CI guest
        # renders nothing, so SPICE's OpenGL path only adds a failure mode.
        virtio_video = null;
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
            # The template's own two, in order: system disk and the installer CDROM it
            # emits empty.
            (
              builtins.elemAt template.devices.disk 0
              // {
                boot.order = 1;
              }
            )
            (builtins.elemAt template.devices.disk 1)
            {
              type = "file";
              device = "cdrom";
              driver = {
                name = "qemu";
                type = "raw";
              };
              source.file = "${windows.payloadIso}";
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
              source.file = "${runnerIso}";
              target = {
                dev = "hdf";
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
                dev = "hdg";
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
          ];
        };
      };
    in
    {
      options.my.services.forgejo-runner.windows = {
        enable = lib.mkEnableOption "a Windows guest registered as a Forgejo Actions runner";

        name = lib.mkOption {
          type = lib.types.str;
          default = "${config.networking.hostName}-windows";
          defaultText = lib.literalExpression ''"''${config.networking.hostName}-windows"'';
          description = "Name the runner registers under.";
        };

        labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "x86_64-windows:host" ];
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
      };

      config = lib.mkIf cfg.enable {
        # The guest is an overlay of that feature's golden image, so it cannot be
        # had without it.
        my.services.windows-vm.enable = true;

        my.virtualisation.libvirt.dhcpHosts = [
          {
            mac = guestMac;
            name = "windows-ci";
            ip = "192.168.122.11";
          }
        ];

        virtualisation.libvirt.connections."qemu:///system".domains = [
          {
            definition = nixvirt.domain.writeXML domain;
            active = true;
          }
        ];

        systemd.services.windows-ci-images = {
          description = "Provision disk images for the Windows CI guest";
          wantedBy = [ "multi-user.target" ];
          before = [
            "libvirtd.service"
            "nixvirt.service"
          ];
          after = [ "windows-vm-images.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ pkgs.qemu-utils ];
          script = ''
            test -e ${stateImage} || qemu-img create -f qcow2 ${stateImage} 32G
            test ! -e ${windows.stateDir}/nvram.fd || test -e ${nvram} || \
              cp ${windows.stateDir}/nvram.fd ${nvram}
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

            sed -n 's/^TOKEN=//p' ${runner.tokenFile} > "$dir/token.txt"

            xorriso -as mkisofs -J -r -V WINCISEED -o ${seedIso}.new "$dir"
            chmod 0400 ${seedIso}.new
            mv ${seedIso}.new ${seedIso}
          '';
        };

        virtualisation.libvirtd.hooks.qemu.windows-ci =
          pkgs.writeShellScript "windows-ci-reset-system-disk" ''
            if [ "$1" != windows-ci ] || [ "$2" != prepare ] || [ "$3" != begin ]; then
              exit 0
            fi

            rm -f ${systemImage}
            ${pkgs.qemu-utils}/bin/qemu-img create -f qcow2 -F qcow2 -b ${baseImage} ${systemImage}
          '';
      };
    };
}
