{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../server.nix
    ../common.nix
    ../services/adguardhome
    ../services/atuin
    ../services/calibre-web
    ../services/forgejo
    ../services/miniflux
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

  ext.btrfs = {
    enable = true;
  };

  networking = {
    hostName = "manyara";
  };

  environment.systemPackages = [ pkgs.coreutils ];

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.sops.secrets.tailscale-authkey.path;
  };

  services.cloudflared.enable = true;

  ext.services.nixpkgs-review.autoDeleteLogs = {
    enable = true;
    environmentFile = config.sops.secrets.gh-token.path;
  };

  sops.secrets.gh-token = { };
}
