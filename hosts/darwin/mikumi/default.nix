{ config, ... }:
{
  imports = [
    ../../../systems/shared/hercules-ci/agent.nix
    ../../../systems/darwin/common.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  my.profiles.base.enable = true;
  my.profiles.server.enable = true;

  networking = {
    hostName = "mikumi";
    knownNetworkServices = [
      "Ethernet"
      "Wi-Fi"
    ];
  };

  nix.settings = {
    max-jobs = 4;
  };

  programs.zsh.enable = true;

  my.services.forgejo-runner = {
    enable = true;
    tokenFile = config.sops.secrets.forgejo-runner-token.path;
  };
  sops.secrets.forgejo-runner-token = {
    sopsFile = ./secrets.yaml;
    # launchd reads the env file as the runner user, so it must own it
    owner = config.services.forgejo-runner.user;
  };

  power = {
    # Enable these options only on Mac mini because MacBook does not support these features
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
  };

  # fails to activate
  # ln: failed to create symbolic link '/etc/pam.d/sudo_local': Operation not permitted
  security.pam.services.sudo_local.enable = false;
}
