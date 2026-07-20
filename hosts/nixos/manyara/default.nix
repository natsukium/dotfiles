{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../../systems/shared/comin/prometheus.nix
    ../../../systems/nixos/common.nix
    ../../../systems/nixos/services/adguardhome
    ../../../systems/nixos/services/atuin
    ../../../systems/nixos/services/calibre-web
    ../../../systems/nixos/services/continuwuity
    ../../../systems/nixos/services/forgejo
    ../../../systems/nixos/services/hermes-agent
    ../../../systems/nixos/services/home-assistant
    ../../../systems/nixos/services/miniflux
    ../../../systems/nixos/services/niks3
    ../../../systems/nixos/services/searxng
    ./hardware-configuration.nix
    inputs.simple-wol-manager.nixosModules.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  my.profiles.base.enable = true;
  my.profiles.server.enable = true;

  my.services.grafana.enable = true;
  my.services.prometheus.enable = true;
  my.services.loki.enable = true;
  my.services.alertmanager.enable = true;
  my.services.blackbox.enable = true;
  my.services.postgres-exporter.enable = true;

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
        # Peers send file modes that match their local user (typically 0644
        # without group write); applying those locally would lock hermes-agent
        # out of files it needs to modify. Ignoring incoming perms lets the
        # syncthing UMask=0002 below produce 0664/2775 entries that the
        # org-sync group can write.
        ignorePerms = true;
      };
    };
  };

  # Shared gid pinned on both manyara and the hermes-agent guest so virtiofs's
  # passthrough mode lines up: files created by syncthing (host uid) and
  # hermes-agent (guest uid) end up in the same gid namespace, and group write
  # bits propagate across the host/guest boundary.
  users.groups.org-sync.gid = 9001;
  users.users.${config.services.syncthing.user}.extraGroups = [
    # syncthing needs write access to /data/books which is owned by calibre-web
    config.services.calibre-web.group
    "org-sync"
  ];
  # microvm.nix runs virtiofsd as the `microvm` user; without org-sync
  # membership it cannot traverse a 2770 directory to expose it to the guest.
  users.users.microvm.extraGroups = [ "org-sync" ];

  # syncthing creates the folder lazily; pre-create with the org-sync group +
  # setgid so new entries inherit the shared gid regardless of who creates
  # them (syncthing on host, or hermes via virtiofs).
  systemd.tmpfiles.rules = [
    "d /var/lib/syncthing/org 2770 ${config.services.syncthing.user} org-sync -"
    # setgid (2xxx) ensures new files/dirs inherit the calibre-web group,
    # so both syncthing (group member) and calibre-web (owner) can access them
    "d /data/books 2775 ${config.services.calibre-web.user} ${config.services.calibre-web.group} -"
  ];
  # default umask 0022 strips group write, preventing calibre-web from modifying
  # files syncthing creates — 0002 preserves group write so both services can coexist
  systemd.services.syncthing.serviceConfig.UMask = "0002";

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
