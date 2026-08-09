{ config, lib, ... }:
{
  services.matrix-continuwuity = {
    enable = true;
    settings.global = {
      server_name = "natsukium.com";
      # Federation off: keep the instance closed while moderation policy
      # (server blocklists, abuse contact, etc.) is undecided. Flip on once
      # those decisions are made and inbound federation can be exposed.
      allow_federation = false;
      # Registration off as the steady state. Accounts are created via the
      # admin command room (`!admin users create-user`) regardless of this
      # flag, so it only needs to be flipped on for the initial admin bootstrap
      # or when temporarily admitting a new user.
      allow_registration = false;
      # serverName is the apex (natsukium.com) but the homeserver itself
      # listens on the matrix subdomain, with delegation handled externally
      # (well-known served from the apex via a separate Worker). Advertise
      # the API on 443 instead of the default 8448 federation port, since
      # the cloudflared tunnel only exposes 443.
      well_known = {
        server = "matrix.natsukium.com:443";
        client = "https://matrix.natsukium.com";
      };
    };
  };

  # The upstream unit is sandboxed (PrivateIPC, RemoveIPC, syscall filter
  # dropping @ipc), so an ExecStart `$(cat ...)` read of the registration
  # token is blocked. Inject via env file instead -- continuwuity reads
  # CONTINUWUITY_* env vars as config overrides, keeping the secret out of
  # the world-readable Nix store.
  systemd.services.continuwuity.serviceConfig.EnvironmentFile =
    config.sops.templates."continuwuity.env".path;

  # Upstream documents two ways to back this up. The online one drives RocksDB's
  # backup engine, but it is reachable only as `!admin server backup-database`
  # from the admin room or at startup through admin_execute, so nothing a timer
  # runs can ask for it, and restoring one means renaming every .sst file by
  # hand and merging two directories. The other is the offline procedure
  # (halt, copy database_path, restore it as it stands), which is what this
  # does. Media sits in media/ under the same directory, so one copy covers it.
  # The cleanup hook runs as ExecStopPost, so the homeserver comes back even
  # when restic fails.
  my.services.restic.backups.continuwuity = {
    # DynamicUser puts the real tree under /var/lib/private and leaves
    # /var/lib/continuwuity as a symlink to it, which restic would archive as a
    # symlink and nothing more.
    paths = [ "/var/lib/private/continuwuity" ];
    prepare = "${config.systemd.package}/bin/systemctl stop continuwuity.service";
    cleanup = "${config.systemd.package}/bin/systemctl start continuwuity.service";
  };

  my.services.cloudflared-tunnel.ingress."matrix.natsukium.com".service =
    "http://localhost:${toString (lib.head config.services.matrix-continuwuity.settings.global.port)}";

  sops.secrets.matrix-registration-token.sopsFile = ./secrets.yaml;
  sops.templates."continuwuity.env" = {
    content = ''
      CONTINUWUITY_REGISTRATION_TOKEN=${config.sops.placeholder.matrix-registration-token}
    '';
    owner = config.services.matrix-continuwuity.user;
    group = config.services.matrix-continuwuity.group;
    mode = "0440";
  };
}
