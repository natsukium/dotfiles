{
  config,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs;
in {
  imports = [
    ../../../modules/nix
    ../common.nix
    ../desktop.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
  ];

  inherit (pkgs.callPackage ./disko-config.nix {disks = ["/dev/nvme1n1"];}) disko;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;

    # it is required to run `nixos-rebuild switch --target ${aarch64-linux machines}`
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "kilimanjaro";
    };
  };

  nix.settings = {
    cores = 4;
    max-jobs = 3;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
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
}
