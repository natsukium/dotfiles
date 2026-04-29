{
  config,
  pkgs,
  ...
}:
let
  # Upstream renders config.yaml from a stage-1 activation script, before
  # /var/lib/hermes is mounted, so the file lands on the ephemeral root and
  # gets shadowed. Re-render here and seed via the systemd unit below instead.
  hermesConfigFile = pkgs.writeText "hermes-config.yaml" (
    builtins.toJSON config.services.hermes-agent.settings
  );
  credentialsDir = "/run/credentials/@system";
in
{
  microvm = {
    vcpu = 2;
    mem = 4096;

    interfaces = [
      {
        type = "user";
        id = "hermes-net";
      }
    ];

    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    # ext4 image, not virtiofs: hermes writes a SQLite database whose WAL/SHM
    # files interact poorly with virtiofs metadata caching.
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

  # Upstream's environmentFiles/authFile run before /var/lib/hermes is mounted,
  # so files land on the ephemeral root. Rewrite .env and config.yaml on every
  # boot; seed auth.json only when absent so the in-VM OAuth refresh state
  # survives rebuilds.
  systemd.services.hermes-agent-secrets-seed = {
    description = "Seed hermes-agent secrets from systemd credentials";
    wantedBy = [ "hermes-agent.service" ];
    before = [ "hermes-agent.service" ];
    unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -o hermes -g hermes -m 2770 /var/lib/hermes/.hermes
      install -o hermes -g hermes -m 0640 \
        ${hermesConfigFile} /var/lib/hermes/.hermes/config.yaml
      install -o hermes -g hermes -m 0640 \
        ${credentialsDir}/hermes-agent.env /var/lib/hermes/.hermes/.env
      if [ ! -f /var/lib/hermes/.hermes/auth.json ]; then
        install -o hermes -g hermes -m 0600 \
          ${credentialsDir}/hermes-agent.auth.json /var/lib/hermes/.hermes/auth.json
      fi
    '';
  };

  # ttyS0 forwarding ships the guest journal out as
  # microvm@hermes-agent.service on the host, where alloy picks it up. Without
  # this the journal stays inside the ephemeral guest root and is lost on
  # reboot — there is no persistent /var/log mount and no inbound shell.
  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  system.stateVersion = "25.11";
}
