{ lib, specialArgs, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../common.nix
    ../desktop.nix
    ../linux-builder.nix
  ];

  system.stateVersion = 6;

  my.services.timemachine.enableLocalSnapshot = true;

  nix.settings = {
    substituters = [ "https://attmcojp.cachix.org" ];
    trusted-public-keys = [ "attmcojp.cachix.org-1:oru6oV4EttotACGO/YDhmsEyPlPSytG6zWUgTRH3BMQ=" ];
  };

  networking = {
    hostName = "work";
    knownNetworkServices = [
      "USB 10/100/1G/2.5G LAN"
      "Wi-Fi"
    ];
  };

  programs = {
    _1password.enable = true; # Integration with the 1Password GUI
    _1password-gui.enable = true;
  };
}
