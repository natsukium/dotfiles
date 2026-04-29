{
  inputs,
  config,
  pkgs,
  hermesSecretsMount,
  hermesSecretsHost,
  ...
}:
let
  # YAML is a strict superset of JSON; upstream's module does the same trick
  # (see hermes-agent's nixosModules.nix: `pkgs.writeText "hermes-config.yaml"
  # (builtins.toJSON cfg.settings)`). We replicate it here because upstream
  # writes config.yaml from a stage-1 activation script — that runs before the
  # state.img volume is mounted onto /var/lib/hermes, so the file ends up on
  # the ephemeral initrd FS and is shadowed away.
  hermesConfigFile = pkgs.writeText "hermes-config.yaml" (
    builtins.toJSON config.services.hermes-agent.settings
  );
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  networking.hostName = "hermes-agent";

  # User-mode QEMU networking issues DHCP from slirp (10.0.2.15) and forwards
  # DNS through the host. Nothing in the VM listens for inbound traffic, so
  # the default-deny firewall is sufficient.
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."10-eth" = {
    matchConfig.Type = "ether";
    networkConfig = {
      DHCP = "yes";
      DNSDefaultRoute = true;
    };
  };

  microvm = {
    hypervisor = "qemu";
    vcpu = 2;
    mem = 4096;

    interfaces = [
      {
        type = "user";
        id = "hermes-net";
        mac = "02:00:00:7e:e1:01";
      }
    ];

    # localhost-only ssh hostfwd so the operator on manyara can reach the
    # guest's sshd via `ssh -p 2222 root@127.0.0.1`. user-mode networking
    # has no other inbound path; this is the only debug-access surface.
    forwardPorts = [
      {
        from = "host";
        host.address = "127.0.0.1";
        host.port = 2222;
        guest.port = 22;
      }
    ];

    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
      {
        # securityModel defaults to "none", presenting files as the virtiofsd
        # UID (root). The host renders the secrets mode 0444 so that's enough
        # for the in-VM hermes user to read without UID alignment.
        source = hermesSecretsHost;
        mountPoint = hermesSecretsMount;
        tag = "hermes-secrets";
        proto = "virtiofs";
      }
    ];

    # ext4 image rather than a virtiofs share because hermes writes a SQLite
    # database whose WAL/SHM files interact poorly with virtiofs metadata
    # caching.
    volumes = [
      {
        image = "state.img";
        mountPoint = "/var/lib/hermes";
        size = 4096;
        label = "hermes-state";
      }
    ];
  };

  services.hermes-agent = {
    enable = true;
    settings.model.provider = "openai-codex";
  };

  # We don't use the upstream module's environmentFiles / authFile because
  # its activation script runs in initrd, before the virtiofs share is
  # mounted — reading from ${hermesSecretsMount} would fail and abort the
  # activation. Seed via a systemd unit instead, ordered after the share
  # mount via RequiresMountsFor + Before=hermes-agent.service. .env and
  # config.yaml are rewritten on every boot so settings changes propagate;
  # auth.json is seeded only on first boot so the in-VM OAuth refresh state
  # is preserved across rebuilds.
  systemd.services.hermes-agent-secrets-seed = {
    description = "Seed hermes-agent secrets from virtiofs share";
    wantedBy = [ "hermes-agent.service" ];
    before = [ "hermes-agent.service" ];
    unitConfig.RequiresMountsFor = [
      hermesSecretsMount
      "/var/lib/hermes"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -o hermes -g hermes -m 2770 /var/lib/hermes/.hermes
      install -o hermes -g hermes -m 0640 \
        ${hermesConfigFile} /var/lib/hermes/.hermes/config.yaml
      install -o hermes -g hermes -m 0640 \
        ${hermesSecretsMount}/env /var/lib/hermes/.hermes/.env
      if [ ! -f /var/lib/hermes/.hermes/auth.json ]; then
        install -o hermes -g hermes -m 0600 \
          ${hermesSecretsMount}/auth.json /var/lib/hermes/.hermes/auth.json
      fi
    '';
  };

  # Forward in-guest journald entries to ttyS0 so the host can read
  # hermes-agent's application logs via `journalctl -u microvm@hermes-agent`.
  # Without this the only way to inspect the agent's behaviour is to
  # interactively log into the VM, which means the diagnostic loop blocks
  # on a working sshd (chicken/egg if hermes-agent itself is failing).
  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  # Operator's ed25519 key from systems/nixos/common.nix.  Pubkey is the
  # only material on disk; the corresponding private key lives on the
  # operator's laptop. Password auth is left off.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu tomoya.otabi@gmail.com"
  ];

  system.stateVersion = "25.05";
}
