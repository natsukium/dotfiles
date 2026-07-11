{ config, pkgs, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../../../systems/darwin/common.nix
    ../../../systems/darwin/desktop.nix
    ../../../systems/darwin/linux-builder.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  my.home.enable = true;
  home-manager.users.${config.my.username} = {
    imports = [
      ../../../homes/darwin/common.nix
      ../../../homes/darwin/desktop.nix
      ../../../modules/profiles/home/base.nix
      ../../../modules/profiles/home/desktop.nix
      ../../../modules/profiles/home/development.nix
      ./accounts.nix
      ./git.nix
    ];

    home.packages = with pkgs; [
      brewCasks.slack
      google-chrome
      google-cloud-sdk
      meetingbar
    ];

    my.programs.just.enableEnhancedCompletion = true;

    services.colima.profiles.default = {
      # Docker Desktop is installed on the work machine
      isActive = false;
      settings = {
        disk = 200;
        kubernetes.enabled = true;
      };
    };
  };

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
