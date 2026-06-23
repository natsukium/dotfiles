{
  config,
  pkgs,
  self,
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
        # microvm.nix made `mac` mandatory; type=user is SLIRP/NAT so the
        # value is cosmetic, but we still pick a stable locally-administered
        # address (02: prefix) so the guest's interface name stays the same
        # across rebuilds.
        mac = "02:00:00:00:48:01";
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
        source = "/var/lib/syncthing/org";
        mountPoint = "/var/lib/hermes/org";
        tag = "org";
        proto = "virtiofs";
      }
    ];

    # Writable upper for /nix/store so the agent can `nix shell nixpkgs#…`.
    # Without it, /nix/var/nix/temproots is RO and every nix-command write fails.
    writableStoreOverlay = "/nix/.rw-store";

    # ext4 image, not virtiofs: hermes writes a SQLite database whose WAL/SHM
    # files interact poorly with virtiofs metadata caching.
    volumes = [
      {
        image = "state.img";
        mountPoint = "/var/lib/hermes";
        size = 4096;
        label = "hermes-state";
      }
      {
        image = "nix-overlay.img";
        mountPoint = "/nix/.rw-store";
        size = 8192;
        # ext4 labels are capped at 16 bytes; "hermes-nix-overlay" (18) gets
        # silently truncated by mkfs to "hermes-nix-overl", leaving the
        # generated fstab's by-label lookup forever unsatisfied.
        label = "hermes-nix-ovl";
      }
    ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # microvm.nix asserts this is off when writableStoreOverlay is set.
    auto-optimise-store = false;
  };

  services.hermes-agent = {
    enable = true;
    settings = {
      model.provider = "openai-codex";
      web.search_backend = "searxng";
    };
    addToSystemPackages = true;
    extraPackages = [
      pkgs.python3
      pkgs.jq
      self.packages.${pkgs.stdenv.hostPlatform.system}.emacs
    ];
    extraDependencyGroups = [ "matrix" ];
  };

  # Pinned to match syncthing's uid/gid on the manyara host (see its
  # default.nix). virtiofsd runs as root and passes ids through unchanged, so
  # files hermes writes land on the host owned by syncthing and vice versa —
  # owner-rw is enough, with no shared group or post-hoc chmod on either side.
  users.users.hermes.uid = 237;
  users.groups.hermes.gid = 237;

  # init.org bakes in ~/dropbox/org, ~/dropbox/org-roam, and
  # ~/.local/share/org-roam.db. Re-pointing those vars in the guest would
  # fork the init.el (the very drift this setup is trying to avoid); instead,
  # satisfy the paths via filesystem symlinks and stub directories so the
  # user's emacs config loads as-is. ~/dropbox/org points at the virtiofs
  # mount; ~/dropbox/org-roam is a local empty dir (org-roam isn't synced
  # yet); ~/.local/share exists so org-roam-db-autosync-mode can create the
  # SQLite db on first run.
  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/dropbox 0750 hermes hermes -"
    "L /var/lib/hermes/dropbox/org - hermes hermes - /var/lib/hermes/org"
    "d /var/lib/hermes/dropbox/org-roam 0770 hermes hermes -"
    "d /var/lib/hermes/.local 0750 hermes hermes -"
    "d /var/lib/hermes/.local/share 0750 hermes hermes -"
  ];

  # Upstream's environmentFiles/authFile run before /var/lib/hermes is mounted,
  # so files land on the ephemeral root. Rewrite .env and config.yaml on every
  # boot; re-seed auth.json only when the deployed credential changes, so a
  # rotated token replaces the stale copy while codex's in-VM OAuth refresh
  # writes survive ordinary rebuilds.
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
      # One-time: hermes's uid/gid changed to 237 to match the host syncthing
      # user. Re-own the persistent state written under the old auto-allocated
      # ids; remove this guard after the first successful deploy.
      if [ ! -e /var/lib/hermes/.uid-migrated ]; then
        chown -R hermes:hermes /var/lib/hermes
        touch /var/lib/hermes/.uid-migrated
      fi

      install -d -o hermes -g hermes -m 2770 /var/lib/hermes/.hermes
      install -o hermes -g hermes -m 0640 \
        ${hermesConfigFile} /var/lib/hermes/.hermes/config.yaml
      install -o hermes -g hermes -m 0640 \
        ${credentialsDir}/hermes-agent.env /var/lib/hermes/.hermes/.env
      # codex rewrites auth.json on every token refresh, so it can't be diffed
      # against the credential directly; stamp the seeded credential's hash on
      # the persistent volume and re-seed only when that hash changes.
      cred=${credentialsDir}/hermes-agent.auth.json
      stamp=/var/lib/hermes/.hermes/.auth.json.seed-hash
      hash=$(sha256sum "$cred" | cut -d' ' -f1)
      if [ "$(cat "$stamp" 2>/dev/null)" != "$hash" ]; then
        install -o hermes -g hermes -m 0600 \
          "$cred" /var/lib/hermes/.hermes/auth.json
        printf '%s\n' "$hash" > "$stamp"
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
