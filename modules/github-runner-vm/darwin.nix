# nix-darwin module: GitHub Actions runner microVMs for macOS.
#
# Builds aarch64-linux guest VMs using vfkit (Apple Virtualization.framework)
# + gvproxy for networking, and manages them as launchd daemons.
# Each VM runs a single GitHub Actions runner.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.my.services.github-runner-vm;
  gvproxy = pkgs.gvproxy;
  maxFilesPerProc = 26214400;

  instanceCount = lib.length (lib.attrNames cfg.instances);
  indices = map (s: builtins.fromJSON s) (lib.attrNames cfg.instances);

  # microvm.nix's nixpkgs (unstable) has vfkit with pty support
  microvmPkgs = import self.inputs.microvm.inputs.nixpkgs {
    system = "aarch64-darwin";
  };

  # macOS 26 (Darwin 25.x) removed VZVirtioConsoleDeviceSerialPortConfiguration,
  # so vfkit's "virtio-serial,stdio" no longer works. We rewrite it to
  # "virtio-serial,pty" and open the PTY to unblock kernel boot.
  # See:
  #   - https://github.com/crc-org/vfkit/pull/259
  #   - https://github.com/utmapp/UTM/issues/5143
  mkVfkit =
    i:
    pkgs.writeShellScriptBin "vfkit" ''
      args=()
      for arg in "$@"; do
        if [ "$arg" = "virtio-serial,stdio" ]; then
          args+=("virtio-serial,pty")
        else
          args+=("$arg")
        fi
      done

      rm -f /tmp/vm-vfkit-${toString i}-*.log
      LOG=$(mktemp /tmp/vm-vfkit-${toString i}-XXXXXX.log)
      ${lib.getExe microvmPkgs.vfkit} "''${args[@]}" > "$LOG" 2>&1 &
      VFKIT_PID=$!

      # Forward SIGTERM/SIGINT to vfkit so launchd stop actually terminates
      # the virtualization process, not just this wrapper script.
      _caught_signal=15
      cleanup() {
        kill "$VFKIT_PID" 2>/dev/null
        if [ -n "''${PTY_PID:-}" ]; then
          kill "$PTY_PID" 2>/dev/null
        fi
        wait "$VFKIT_PID" 2>/dev/null
        exit $((128 + _caught_signal))
      }
      trap '_caught_signal=15; cleanup' TERM
      trap '_caught_signal=2; cleanup' INT

      for _ in $(seq 1 30); do
        PTY=$(${pkgs.gnugrep}/bin/grep -o '/dev/ttys[0-9]*' "$LOG" 2>/dev/null | head -1 || true)
        [ -n "$PTY" ] && [ -c "$PTY" ] && break
        sleep 1
      done
      if [ -n "$PTY" ]; then
        bash -c "exec 3<>$PTY; cat <&3 >> /var/lib/github-runner-vm-${toString i}/logs/console.log" &
        PTY_PID=$!
      fi

      wait "$VFKIT_PID"
      [ -n "''${PTY_PID:-}" ] && kill "$PTY_PID" 2>/dev/null
    '';

  mkGuestNixos =
    i:
    let
      inst = cfg.instances.${toString i};
    in
    self.inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        runnerIndex = i;
        inherit (cfg) url tokenFile sshAuthorizedKeys;
        inherit (inst) runnerNamePrefix extraLabels diskSize;
      };
      modules = [
        self.inputs.microvm.nixosModules.microvm
        ./guest.nix
        {
          microvm.vcpu = inst.vcpu;
          microvm.mem = inst.mem;

          microvm.vmHostPackages = pkgs;
          microvm.vfkit.package = mkVfkit i;

          microvm.shares = lib.mkForce [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              # Host-decrypted sops secrets shared via virtiofs
              proto = "virtiofs";
              tag = "secrets";
              source = cfg.hostSecretsPath;
              mountPoint = "/var/secrets";
            }
            {
              proto = "virtiofs";
              tag = "logs";
              source = "/var/lib/github-runner-vm-${toString i}/logs";
              mountPoint = "/var/log/shared";
            }
          ];

          microvm.vfkit.extraArgs = lib.mkForce [
            "--device"
            "virtio-net,unixSocketPath=/tmp/github-runner-vm-${toString i}-vfkit.sock,mac=02:00:00:00:00:${
              lib.fixedWidthString 2 "0" (lib.toHexString (2 + i))
            }"
          ];
        }
      ]
      ++ cfg.extraGuestModules;
    };

  mkRunner = i: (mkGuestNixos i).config.microvm.runner.vfkit;

  mkLaunchScript =
    i:
    let
      runner = mkRunner i;
    in
    pkgs.writeShellScript "github-runner-vm-${toString i}-launch" ''
      set -euo pipefail

      mkdir -p /var/lib/github-runner-vm-${toString i}/logs

      SOCK=/tmp/github-runner-vm-${toString i}-gvproxy.sock
      VFKIT_SOCK=/tmp/github-runner-vm-${toString i}-vfkit.sock

      # Clean up stale sockets from previous crash
      rm -f "$SOCK" "$VFKIT_SOCK"

      # Start gvproxy for VM networking
      # Each instance needs a unique SSH forwarding port to avoid
      # "address already in use" when multiple VMs run on the same host.
      ${lib.getExe' gvproxy "gvproxy"} \
        -listen "unix://$SOCK" \
        -listen-vfkit "unixgram://$VFKIT_SOCK" \
        -ssh-port ${toString (22220 + i)} &
      GVPROXY_PID=$!

      cleanup() {
        kill "$GVPROXY_PID" 2>/dev/null || true
        wait "$GVPROXY_PID" 2>/dev/null || true
      }
      trap cleanup EXIT TERM INT

      # Give gvproxy time to create sockets
      sleep 2

      # Start microvm (blocks until VM exits)
      ${runner}/bin/microvm-run
    '';
in
{
  options = {
    my.services.github-runner-vm = {
      enable = lib.mkEnableOption "GitHub Actions runner microVMs";

      count = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of runner VMs to launch on this host. Used to generate default instances when `instances` is not set.";
      };

      instances = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              mem = lib.mkOption {
                type = lib.types.int;
                default = cfg.mem;
                description = "Memory for this VM in MiB";
              };
              vcpu = lib.mkOption {
                type = lib.types.int;
                default = cfg.vcpu;
                description = "Number of virtual CPUs for this VM";
              };
              extraLabels = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = cfg.extraLabels;
                description = "Extra labels to apply to this runner";
              };
              diskSize = lib.mkOption {
                type = lib.types.int;
                default = cfg.diskSize;
                description = "Persistent /var volume size in MiB for this VM";
              };
              runnerNamePrefix = lib.mkOption {
                type = lib.types.str;
                default = cfg.runnerNamePrefix;
                description = "Prefix for this runner's name";
              };
            };
          }
        );
        default = lib.genAttrs (map toString (lib.range 1 cfg.count)) (_: { });
        description = "Per-instance configuration. Keys are instance indices (as strings). Unset options inherit from top-level defaults.";
      };

      url = lib.mkOption {
        type = lib.types.str;
        description = "GitHub organization or repository URL for runner registration";
        example = "https://github.com/myorg";
      };

      runnerNamePrefix = lib.mkOption {
        type = lib.types.str;
        default = "linux-arm64";
        description = "Prefix for runner names. Each runner is named '{prefix}-{index}'.";
      };

      extraLabels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra labels to apply to each runner";
      };

      tokenFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/secrets/github-runner-token";
        description = "Path to the GitHub runner registration token file inside the VM";
      };

      hostSecretsPath = lib.mkOption {
        type = lib.types.str;
        default = "/run/secrets";
        description = "Host path to sops-decrypted secrets, shared to VMs via virtiofs";
      };

      vcpu = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "Number of virtual CPUs per VM";
      };

      mem = lib.mkOption {
        type = lib.types.int;
        default = 16384;
        description = "Memory per VM in MiB";
      };

      diskSize = lib.mkOption {
        type = lib.types.int;
        default = 51200;
        description = "Persistent /var volume size in MiB";
      };

      sshAuthorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH public keys to authorize for root login on guest VMs";
      };

      extraGuestModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [ ];
        description = "Extra NixOS modules to include in the guest VM configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # launchd refuses to start a service whose WorkingDirectory does not
    # exist (exit 78 / EX_CONFIG), and the launch script's mkdir runs too
    # late — it is the service itself.  Create the directories during
    # system activation so they are present before launchd evaluates the
    # plist.
    system.activationScripts.postActivation.text = ''
      # Multiple VMs sharing /nix/store via virtiofs consume file
      # descriptors rapidly; raise the system-wide limit to prevent
      # "Too many open files in system" during Nix builds in guests.
      sysctl -w kern.maxfilesperproc=${toString maxFilesPerProc}
      sysctl -w kern.maxfiles=${toString (maxFilesPerProc * (instanceCount + 1))}
    ''
    + lib.concatMapStringsSep "\n" (i: "mkdir -p /var/lib/github-runner-vm-${toString i}/logs") indices;

    launchd.daemons = lib.listToAttrs (
      map (i: {
        name = "github-runner-vm-${toString i}";
        value = {
          serviceConfig = {
            ProgramArguments = [
              "/bin/sh"
              "-c"
              "${mkLaunchScript i}"
            ];
            # microvm-run creates var.img in its working directory
            WorkingDirectory = "/var/lib/github-runner-vm-${toString i}";
            KeepAlive = true;
            RunAtLoad = true;
            # Nix builds open many files; raise limits to prevent
            # gvproxy/vfkit from hitting "too many open files".
            SoftResourceLimits = {
              NumberOfFiles = 1048576;
            };
            HardResourceLimits = {
              NumberOfFiles = 1048576;
            };
            StandardOutPath = "/var/log/github-runner-vm-${toString i}.log";
            StandardErrorPath = "/var/log/github-runner-vm-${toString i}.log";
          };
        };
      }) indices
    );
  };
}
