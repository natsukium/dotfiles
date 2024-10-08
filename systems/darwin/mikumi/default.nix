{ pkgs, ... }:
{
  imports = [ ../common.nix ];

  nix.settings = {
    max-jobs = 4;
  };

  programs.zsh.enable = true;

  services.cachix-agent = {
    enable = true;
    name = "mikumi";
    # sops-nix does not yet support nix-darwin
    # https://github.com/Mic92/sops-nix/pull/558
    credentialsFile = "/etc/cachix-agent.token";
  };
}
