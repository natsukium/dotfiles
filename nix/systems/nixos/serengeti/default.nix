{ config, specialArgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    initialPassword = "";
    extraGroups = [ "wheel" ];
  };

  networking = {
    hostName = "serengeti";
  };

  nix.settings = {
    max-jobs = 2;
  };
}
