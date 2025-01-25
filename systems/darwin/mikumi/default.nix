{ config, pkgs, ... }:
{
  imports = [
    ../../server.nix
    ../../shared/hercules-ci/agent.nix
    ../common.nix
  ];

  networking.hostName = "mikumi";

  nix.settings = {
    max-jobs = 4;
  };

  programs.zsh.enable = true;

  services.cachix-agent = {
    enable = true;
    name = "mikumi";
    credentialsFile = config.sops.secrets.cachix-agent-token.path;
  };

  power = {
    # Enable these options only on Mac mini because MacBook does not support these features
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
  };

  sops.secrets.cachix-agent-token = {
    sopsFile = ./secrets.yaml;
  };
}
