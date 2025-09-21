{ config, pkgs, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/base.nix
    ../../server.nix
    ../../shared/hercules-ci/agent.nix
    ../common.nix
  ];

  networking.hostName = "mikumi";

  nix.settings = {
    max-jobs = 4;
  };

  programs.zsh.enable = true;

  power = {
    # Enable these options only on Mac mini because MacBook does not support these features
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
  };

  # fails to activate
  # ln: failed to create symbolic link '/etc/pam.d/sudo_local': Operation not permitted
  security.pam.services.sudo_local.enable = false;
}
