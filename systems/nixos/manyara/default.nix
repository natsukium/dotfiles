{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../../modules/profiles/nixos/base.nix
    ../../../modules/profiles/nixos/server.nix
    ../../shared/comin/prometheus.nix
    ../common.nix
    ../services/adguardhome
    ../services/atuin
    ../services/calibre-web
    ../services/continuwuity
    ../services/forgejo
    ../services/grafana
    ../services/hermes-agent
    ../services/home-assistant
    ../services/loki
    ../services/miniflux
    ../services/niks3
    ../services/prometheus
    ../services/searxng
    ./hardware-configuration.nix
    inputs.simple-wol-manager.nixosModules.default
  ];

  inherit (pkgs.callPackage ./disko-config.nix { disks = [ "/dev/nvme0n1" ]; }) disko;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };

  networking = {
    hostName = "manyara";
  };

  environment.systemPackages = [ pkgs.coreutils ];

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.sops.secrets.tailscale-authkey.path;
  };

  services.cloudflared = {
    enable = true;
    certificateFile = config.sops.secrets.cloudflared-tunnel-cert.path;
  };

  my.services.cloudflared-tunnel = {
    enable = true;
    id = "acfc103f-c6b4-4cef-8269-e1985b80e1ac";
    credentialsFile = config.sops.secrets.cloudflared-tunnel.path;
  };

  sops.secrets.cloudflared-tunnel = {
    sopsFile = ./secrets.yaml;
  };

  services.simple-wol-manager = {
    enable = true;
    host = "0.0.0.0";
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiAddress = "0.0.0.0:8384";
    key = config.sops.secrets.syncthing-key.path;
    cert = config.sops.secrets.syncthing-cert.path;
    settings = {
      devices.kilimanjaro.id = "TGY53EL-MT6DGIB-MJA6B4K-XVPA2KA-M3JHXPJ-GXLUOYH-6656M47-65HZPAI";
      # User-level syncthing instances have separate certs from the system-level
      # instances above, so they need distinct device.
      devices.kilimanjaro-user.id = "YOF7OZK-SCMKTNA-T2GY7NV-DO6C2FG-GCXQITS-MVQMDLS-6JRS6OY-B4QLNQU";
      devices.android.id = "4NKRMZU-E6RYTI2-Y5ZA3ER-BX2RGX6-MGBOSRI-ONAZJGU-BSXU6YC-TEU5SAT";
      folders.calibre-library = {
        path = "/data/books";
        devices = [ "kilimanjaro" ];
        # syncthing runs as a different user from the directory owner (calibre-web),
        # so it cannot chown/chmod synced files — permission sync must be disabled
        ignorePerms = true;
      };
      # The org folder is synced into the host, then exposed to the
      # hermes-agent guest via virtiofs (see microvm.vms.hermes-agent below).
      # Running syncthing inside the guest would need another state volume and
      # a second device ID per host; keeping the daemon on the host reuses the
      # existing cert/key and keeps the VM closer to ephemeral.
      folders.org = {
        path = "/var/lib/syncthing/org";
        devices = [
          "kilimanjaro-user"
          "android"
        ];
        # hermes (guest) shares syncthing's uid across virtiofs, so the file
        # owner is the same identity on both sides and owner-rw always
        # suffices. Ignore peer-sent modes to avoid resync churn.
        ignorePerms = true;
      };
    };
  };

  # syncthing (host) and the hermes-agent guest share this uid. virtiofsd runs
  # as root and passes uids through unchanged, so files either side writes are
  # owned by the same identity on the host: owner-rw is enough, with no shared
  # group, umask widening, setgid, or periodic chmod to keep group access alive
  # (hermes's atomic writer creates files 0600, which no create-time mechanism
  # can widen for a group — only a shared owner avoids that). Pinned to
  # syncthing's existing auto-allocated value so host ownership is unchanged;
  # the guest pins hermes to the same number (see guest.nix). A third writer on
  # this tree would not fit this 1:1 scheme and would need the group model back.
  users.users.${config.services.syncthing.user} = {
    uid = 237;
    # syncthing needs write access to /data/books which is owned by calibre-web.
    extraGroups = [ config.services.calibre-web.group ];
  };
  users.groups.${config.services.syncthing.group}.gid = 237;

  systemd.tmpfiles.rules = [
    # syncthing creates this lazily; pre-create it owned by syncthing (= hermes
    # uid 237) so the guest can rw it from the first boot.
    "d /var/lib/syncthing/org 0700 ${config.services.syncthing.user} ${config.services.syncthing.group} -"
    # setgid (2xxx) ensures new files/dirs inherit the calibre-web group,
    # so both syncthing (group member) and calibre-web (owner) can access them
    "d /data/books 2775 ${config.services.calibre-web.user} ${config.services.calibre-web.group} -"
  ];
  # calibre-web must modify book files syncthing creates under /data/books;
  # default umask 0022 strips group write, so 0002 keeps the shared calibre-web
  # group writable. (The org tree no longer relies on this — see the uid pin.)
  systemd.services.syncthing.serviceConfig.UMask = "0002";

  # One-time: dropping the org-sync group leaves legacy org files owned by the
  # guest's old (pre-237) uid unreachable to syncthing. Re-own the tree once;
  # remove this unit after the first successful deploy.
  systemd.services.org-uid-migrate = {
    description = "Re-own org tree to syncthing after the hermes uid alignment";
    wantedBy = [ "syncthing.service" ];
    before = [ "syncthing.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Stamp lives outside the synced tree so syncthing never propagates it.
      stamp=/var/lib/syncthing/.org-uid-migrated
      if [ ! -e "$stamp" ]; then
        ${pkgs.coreutils}/bin/chown -R \
          ${config.services.syncthing.user}:${config.services.syncthing.group} \
          /var/lib/syncthing/org
        ${pkgs.coreutils}/bin/touch "$stamp"
      fi
    '';
  };

  sops.secrets.syncthing-key = {
    sopsFile = ./syncthing.yaml;
    owner = config.services.syncthing.user;
  };
  sops.secrets.syncthing-cert = {
    sopsFile = ./syncthing.yaml;
    owner = config.services.syncthing.user;
  };

  networking.firewall.allowedTCPPorts = [ 8384 ];

  sops.secrets.cloudflared-tunnel-cert = { };
}
