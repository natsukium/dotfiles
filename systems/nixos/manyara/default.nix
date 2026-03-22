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
    ../services/forgejo
    ../services/grafana
    ../services/miniflux
    ../services/prometheus
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
      folders.calibre-library = {
        path = "/data/books";
        devices = [ "kilimanjaro" ];
      };
    };
  };

  # syncthing needs write access to /data/books which is owned by calibre-web
  users.users.${config.services.syncthing.user}.extraGroups = [ config.services.calibre-web.group ];
  systemd.tmpfiles.rules = [
    "d /data/books 0775 ${config.services.calibre-web.user} ${config.services.calibre-web.group} -"
  ];

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
