{
  config,
  inputs,
  ...
}:
let
  matrix = config.services.matrix-continuwuity.settings.global;

  # Loopback-only forward into the guest, shared with the ssh_config entry below
  # so the alias and the forward cannot drift apart.
  sshPort = 2222;
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ./alloy.nix
  ];

  sops.secrets = {
    "hermes-agent/matrix-access-token".sopsFile = ./secrets.yaml;
    "hermes-agent/matrix-recovery-key".sopsFile = ./secrets.yaml;
    "hermes-agent/auth-json" = {
      sopsFile = ./auth.json;
      format = "binary";
      # microvm@hermes-agent.service runs qemu as microvm:kvm and reads this
      # via SMBIOS OEM strings (microvm.credentialFiles below).
      owner = "microvm";
      group = "kvm";
      mode = "0440";
    };
  };

  # The Grafana MCP endpoint and its bearer token are composed here rather than
  # in the guest: the guest has no view of the host's port choices, and the
  # token has to come from the host's sops tree either way. hermes resolves the
  # ${VAR} references in its mcp_servers entry from this same file.
  #
  # MATRIX_ALLOWED_USERS pins DM authority to the operator so federation peers
  # cannot drive the bot. MATRIX_ENCRYPTION is required because Element DMs are
  # E2EE-by-default — without it the bot only sees undecryptable
  # m.room.encrypted events. MATRIX_RECOVERY_KEY lets the bot self-sign its
  # device on every startup; otherwise it stays unverified and Element refuses
  # to share Megolm sessions with it.
  sops.templates."hermes-agent.env" = {
    content = ''
      MATRIX_HOMESERVER=${matrix.well_known.client}
      MATRIX_USER_ID=@ai-agent:${matrix.server_name}
      MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes-agent/matrix-access-token"}
      MATRIX_ALLOWED_USERS=@natsukium:${matrix.server_name}
      MATRIX_ENCRYPTION=true
      MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes-agent/matrix-recovery-key"}
      SEARXNG_URL=http://10.0.2.2:${toString config.services.searx.settings.server.port}
      MCP_GRAFANA_URL=http://10.0.2.2:${toString config.my.services.mcp-grafana.ports.ro}/mcp
      MCP_GRAFANA_TOKEN=${config.sops.placeholder."mcp-grafana-ro-server-token"}
    '';
    owner = "microvm";
    group = "kvm";
    mode = "0440";
  };

  microvm.autostart = [ "hermes-agent" ];

  # The guest is only reachable through the loopback forward, which is awkward to
  # type and easy to misremember.
  programs.ssh.extraConfig = ''
    Host hermes-agent
      HostName 127.0.0.1
      Port ${toString sshPort}
      User root
  '';

  # SMBIOS OEM strings rather than a virtiofs share: systemd in the guest
  # surfaces these at /run/credentials/@system/<name> before any unit starts,
  # avoiding the bespoke RequiresMountsFor + writable-share-dir setup the
  # virtiofs flow needed.
  microvm.vms.hermes-agent = {
    extraModules = [ inputs.hermes-agent.nixosModules.default ];
    config = {
      imports = [ ./guest.nix ];
      _module.args = {
        self = inputs.self;
        operatorKeys = config.users.users.${config.my.username}.openssh.authorizedKeys.keys;
        inherit sshPort;
      };
      microvm.credentialFiles = {
        "hermes-agent.env" = config.sops.templates."hermes-agent.env".path;
        "hermes-agent.auth.json" = config.sops.secrets."hermes-agent/auth-json".path;
      };
      nix.registry.nixpkgs.flake = inputs.nixpkgs;
    };
  };
}
