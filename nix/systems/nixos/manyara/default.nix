{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (inputs) tsnsrv;
in
{
  imports = [
    ../common.nix
    ../services/adguardhome
    ../services/atuin
    ../services/forgejo
    ../services/hydra
    ../services/miniflux
    ./hardware-configuration.nix
    tsnsrv.nixosModules.default
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
}
