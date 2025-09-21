{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../../modules/profiles/nixos/base.nix
    ../../server.nix
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

  ext.services.nixpkgs-review.autoDeleteLogs = {
    enable = true;
    environmentFile = config.sops.secrets.gh-token.path;
  };

  sops.secrets.gh-token = { };
  sops.secrets.cloudflared-tunnel-cert = { };
}
