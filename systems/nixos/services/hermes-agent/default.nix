{
  config,
  inputs,
  lib,
  ...
}:
let
  vmRoot = "/var/lib/microvms/hermes-agent";
  hermesSecretsHost = "${vmRoot}/secrets";
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ./alloy.nix
  ];

  sops.secrets = {
    "hermes-agent/matrix-access-token" = {
      sopsFile = ./secrets.yaml;
    };
    "hermes-agent/matrix-recovery-key" = {
      sopsFile = ./secrets.yaml;
    };
    # Whole-file binary secret so auth.json stays a real, jq-able JSON file
    # on disk; format = "json" would split each leaf into its own key, forcing
    # us to encode the codex schema in Nix.
    "hermes-agent/auth-json" = {
      sopsFile = ./auth.json;
      format = "binary";
    };
  };

  # MATRIX_ALLOWED_USERS pins DM authority to the operator's account so
  # federation peers (or any future-room invitees) cannot drive the bot.
  # Any prompt-injection-flavoured exfil scenario still requires the bot
  # to obey instructions, but at least it only obeys instructions from us.
  # Matrix DMs are E2EE-by-default in Element, so without MATRIX_ENCRYPTION the
  # bot receives only undecryptable m.room.encrypted events and silently drops
  # them. The upstream Python package already pulls in mautrix[encryption] and
  # python-olm, so flipping this flag is sufficient — no extra system libs.
  # MATRIX_RECOVERY_KEY lets hermes self-sign its own device on every startup
  # via the bot's cross-signing master key (stored in the homeserver's secret
  # storage). Without this the bot's device stays unverified and other
  # Matrix clients (Element) may refuse to share Megolm sessions with it.
  sops.templates."hermes-agent.env".content = ''
    MATRIX_HOMESERVER=https://matrix.natsukium.com
    MATRIX_USER_ID=@ai-agent:natsukium.com
    MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes-agent/matrix-access-token"}
    MATRIX_ALLOWED_USERS=@natsukium:natsukium.com
    MATRIX_ENCRYPTION=true
    MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes-agent/matrix-recovery-key"}
  '';

  # `sops.templates.<name>.path` only creates a symlink to /run/secrets/rendered/<name>;
  # virtiofs forwards the symlink verbatim to the guest, where /run/secrets
  # does not exist and the link dangles. Copy the rendered bytes verbatim
  # into the share dir as real files instead. Mode 0444 lets the guest
  # hermes user read them under virtiofs's default `none` security model
  # (which presents the daemon UID rather than mapping host owners); the
  # parent dir's 0750 still gates host-side access to microvm/kvm members.
  system.activationScripts.hermes-agent-share = lib.stringAfter [ "setupSecrets" ] ''
    install -d -m 0750 -o microvm -g kvm ${vmRoot}
    install -d -m 0750 -o microvm -g kvm ${hermesSecretsHost}
    install -m 0444 -o microvm -g kvm \
      ${config.sops.templates."hermes-agent.env".path} ${hermesSecretsHost}/env
    install -m 0444 -o microvm -g kvm \
      ${config.sops.secrets."hermes-agent/auth-json".path} ${hermesSecretsHost}/auth.json
  '';

  microvm.vms.hermes-agent = {
    specialArgs = {
      inherit inputs hermesSecretsHost;
      hermesSecretsMount = "/run/host-secrets";
    };
    config = ./guest.nix;
  };
}
