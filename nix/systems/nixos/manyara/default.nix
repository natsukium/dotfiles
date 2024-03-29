{
  inputs,
  config,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) username;
  inherit (inputs) disko tsnsrv;
in
{
  imports = [
    ../common.nix
    ../services/hydra
    ../services/miniflux
    ./hardware-configuration.nix
    disko.nixosModules.disko
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

  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    initialPassword = "";
    extraGroups = [ "wheel" ];
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
