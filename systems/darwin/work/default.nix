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

  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    loadModels = [
      "gemma4:31b"
      "gemma4:e4b"
      "nemotron-3-super:120b"
      "nemotron3:33b"
      "qwen3.6:27b"
      "qwen3.6:35b"
    ];
  };
}
