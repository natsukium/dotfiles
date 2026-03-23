# NixOS configuration for a GitHub Actions runner microVM.
# Each VM runs a single runner (aarch64-linux) via vfkit on macOS.
# Runner-specific values are passed via specialArgs.
{
  pkgs,
  lib,
  runnerIndex ? 1,
  url,
  runnerNamePrefix ? "linux-arm64",
  extraLabels ? [ ],
  tokenFile ? "/var/secrets/github-runner-token",
  diskSize ? 51200,
  ...
}:
let
  runnerName = "${runnerNamePrefix}-${toString runnerIndex}";
  commonTools = import ./tools.nix pkgs;
in
{
  # ---------- Hypervisor (vfkit on macOS) ----------
  microvm = {
    hypervisor = "vfkit";

    # gvproxy handles networking via vfkit.extraArgs in flake-module.nix
    interfaces = [ ];

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = diskSize;
      }
    ];

    # Writable overlay for /nix/store backed by persistent /var
    writableStoreOverlay = "/var/nix-rw-store";
  };

  # ---------- Networking ----------
  networking = {
    hostName = "github-runner-vm-${toString runnerIndex}";
    firewall.enable = false;
    interfaces.enp0s1.useDHCP = true;
    resolvconf.enable = false;
    enableIPv6 = false;
  };

  services = {
    resolved.enable = false;

    # ---------- GitHub Actions Runner ----------
    github-runners.${runnerName} = {
      enable = true;
      inherit url tokenFile;
      replace = true;
      extraPackages = commonTools;
      inherit extraLabels;
      extraEnvironment = {
        BASH_ENV = "/etc/profile.d/nix-profile.sh";
      };
      workDir = "/var/lib/github-runner-work/${runnerName}";
      user = "github-runner";
      group = "github-runner";
    };

    # ---------- SSH ----------
    # Host key in /var (persistent volume) to avoid host key change warnings on reboot
    openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/var/lib/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };
  };

  environment.etc = {
    "resolv.conf".text = ''
      nameserver 1.1.1.1
      nameserver 8.8.8.8
    '';
    "profile.d/nix-profile.sh".text = ''
      export PATH="$HOME/.nix-profile/bin:$PATH"
    '';
  };

  # ---------- Fix case-hacked iptables extensions ----------
  # macOS APFS is case-insensitive, so sharing /nix/store via virtiofs
  # causes Nix's case hack to mangle filenames (e.g. libxt_mark.so ->
  # libxt_mark.so~nix~case~hack~1). iptables can't find its extensions.
  systemd = {
    services = {
      fix-iptables-case-hack = {
        description = "Fix case-hacked iptables extension filenames";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "fix-iptables-case-hack" ''
            set -euo pipefail
            XTDIR=/var/lib/xtables-fixed
            rm -rf "$XTDIR"
            mkdir -p "$XTDIR"

            SRCDIR="${pkgs.iptables.lib}/lib/xtables"

            for f in "$SRCDIR"/*; do
              [ -f "$f" ] || continue
              base="$(basename "$f")"
              clean="''${base%%\~nix\~case\~hack\~*}"
              cp -f "$f" "$XTDIR/$clean"
            done
          '';
        };
      };

      # Stream runner logs to virtiofs-shared directory so the host
      # can `tail -f /var/lib/github-runner-vm-{i}/logs/runner.log`
      github-runner-log-forwarder = {
        description = "Forward github-runner journal to shared log";
        after = [ "var-log-shared.mount" ];
        requires = [ "var-log-shared.mount" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.systemd}/bin/journalctl -f -u \"github-runner-*\" --no-hostname -o short-iso >> /var/log/shared/runner.log'";
          Restart = "always";
        };
      };

      github-runner-token-wait = {
        description = "Wait for github-runner token to appear";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "wait-for-token" ''
            for i in $(seq 1 120); do
              [ -s ${tokenFile} ] && exit 0
              sleep 1
            done
            echo "Timed out waiting for ${tokenFile}" >&2
            exit 1
          '';
        };
      };

      # vfkit serial console is handled by the PTY wrapper
      "serial-getty@ttyS0".enable = false;
      "serial-getty@hvc0".enable = false;

      "github-runner-${runnerName}" = {
        # Host-side sops decryption may finish after the VM boots;
        # block until the token appears via virtiofs.
        requires = [ "github-runner-token-wait.service" ];
        after = [ "github-runner-token-wait.service" ];
        serviceConfig = {
          SupplementaryGroups = [ "docker" ];
          # Ensure the runner restarts after crashes or unexpected exits
          Restart = lib.mkForce "always";
          RestartSec = "5s";
        };
      };
    };

    tmpfiles.rules = [
      "d /var/lib/github-runner-work 0755 github-runner github-runner -"
      "d /var/lib/github-runner-work/${runnerName} 0700 github-runner github-runner -"
    ];
  };

  environment.variables.XTABLES_LIBDIR = "/var/lib/xtables-fixed";

  # ---------- Docker ----------
  # Docker for runner jobs that need container builds.
  # TCP listener allows host access via vm-ssh port forwarding if needed.
  virtualisation.docker = {
    enable = true;
    listenOptions = [
      "/run/docker.sock"
      "0.0.0.0:2375"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users = {
    github-runner = {
      isSystemUser = true;
      group = "github-runner";
    };
    root.initialPassword = "root";
  };
  users.groups.github-runner = { };

  programs.nix-ld.enable = true;

  # ---------- System packages ----------
  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    jq
    iptables
  ];

  system.stateVersion = "25.11";
}
