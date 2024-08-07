{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../../modules/nix
    ../common.nix
    ../desktop.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
  ];

  inherit
    (pkgs.callPackage ./disko-config.nix {
      disks = [ "/dev/disk/by-id/nvme-MS950G75PCIe4_2048G_30107347368" ];
    })
    disko
    ;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;

    # it is required to run `nixos-rebuild switch --target ${aarch64-linux machines}`
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  services.btrfs.autoScrub.enable = true;

  networking = {
    hostName = "kilimanjaro";
    wireless = {
      enable = true;
      environmentFile = config.sops.secrets.wifi.path;
      networks."82128927-5G".pskRaw = "@home@";
    };
  };

  fileSystems."/persistent".neededForBoot = true;

  sops.secrets.wifi = { };

  nix.settings = {
    max-jobs = 4;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    # open kernel module is too unstable and often incompatible with the runtime
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  nixpkgs.config.cudaSupport = true;

  programs.nix.target.nvidia = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  dualboot.enable = true;
}
