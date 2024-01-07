{
  inputs,
  config,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) username;
  inherit (inputs) disko;
in
{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    disko.nixosModules.disko
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
}
