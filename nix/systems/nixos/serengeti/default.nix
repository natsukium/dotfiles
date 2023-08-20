{
  config,
  specialArgs,
  ...
}: let
  inherit (specialArgs) username;
in {
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
    extraGroups = ["wheel"];
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
    ];
  };

  networking = {
    hostName = "serengeti";
    firewall = {
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [config.services.tailscale.port];
    };
  };

  nix.settings = {
    cores = 2;
    max-jobs = 2;
  };
}
