{
  config,
  pkgs,
  self,
  operatorKeys,
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

  # web_extract had no usable backend: SearXNG only searches, and every
  # extract-capable provider hermes ships is a paid API. trafilatura covers it
  # locally, but it cannot go into the venv — its closure propagates certifi,
  # charset-normalizer and urllib3, which the packaging's collision check
  # rejects — so it runs as its own executable that the plugin drives.
  webExtractor = pkgs.writers.writePython3Bin "hermes-web-extract" {
    libraries = with pkgs.python3Packages; [
      trafilatura
      httpx
    ];
    # The writer's flake8 defaults to 79 columns; the rest of the tree is
    # formatted at 88, and reflowing signatures to satisfy it reads worse.
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./web-extract/extract.py);

  # The store path is baked in rather than resolved from PATH: the plugin is
  # imported by hermes' own interpreter, whose environment need not contain
  # the guest's user profile.
  webExtractPlugin = pkgs.linkFarm "hermes-web-localextract" {
    "plugin.yaml" = ./web-extract/plugin.yaml;
    "__init__.py" = ./web-extract/__init__.py;
    "provider.py" = pkgs.replaceVars ./web-extract/provider.py {
      extractor = "${webExtractor}/bin/hermes-web-extract";
    };
  };
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

    # Loopback-only inbound SSH (the serial is taken by journal forwarding).
    # 127.0.0.1 limits reach to holders of a manyara shell.
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
      model.default = "gpt-5.4-mini";
      web.search_backend = "searxng";
      web.extract_backend = "localextract";
      # Bundled backends auto-load, but a plugin under the hermes home is
      # user-installed and stays inert until it is named here.
      plugins.enabled = [ "web/localextract" ];
    };
    addToSystemPackages = true;
    extraPackages = [
      pkgs.python3
      pkgs.jq
      self.packages.${pkgs.stdenv.hostPlatform.system}.emacs
    ];
    extraDependencyGroups = [ "matrix" ];
  };

  # hermes discovers user plugins under its home, which lives on the
  # persistent volume; tmpfiles re-points the link on each boot so a rebuilt
  # plugin takes effect without the stale copy surviving in the state image.
  systemd.tmpfiles.settings."10-hermes-plugins" = {
    "/var/lib/hermes/.hermes/plugins/web/localextract"."L+" = {
      user = "hermes";
      group = "hermes";
      argument = "${webExtractPlugin}";
    };
  };

  # Shared with the manyara host (same gid 9001) so virtiofs passthrough
  # preserves the group identity: files hermes writes land on the host with
  # gid org-sync, and files syncthing writes are reachable here via the
  # same group. hermes is added to the group so it can rw the org tree.
  # The upstream hermes-agent module already sets UMask=0007, which keeps
  # group write (files 0660, dirs 0770) so syncthing on the host can update
  # subtrees hermes creates without a separate UMask override here.
  users.groups.org-sync.gid = 9001;
  users.users.hermes.extraGroups = [ "org-sync" ];

  # Pin ids; the ephemeral guest root re-derives uids each boot, so an
  # auto-allocated uid drifts on redeploy and orphans files on the persistent
  # /var/lib/hermes volume (hermes can then no longer open its own gateway.lock).
  users.users.hermes.uid = 9000;
  users.groups.hermes.gid = 9000;

  # Key-only root login for occasional inspection and state repair.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = operatorKeys;

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
  # reboot — there is no persistent /var/log mount.
  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  # hermes stamps the system clock into its prompt (and cron fires in local
  # time), so leaving the guest on its default UTC makes its sense of "now" 9h off.
  time.timeZone = "Asia/Tokyo";

  system.stateVersion = "25.11";
}
