{
  config,
  pkgs,
  inputs,
  ...
}:
{
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;

    instances.default = {
      enable = true;
      name = config.networking.hostName;
      url = "https://git.natsukium.com";
      tokenFile = config.sops.secrets.gitea-actions-runner-token.path;
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
        "nix:host"
      ];
      # Setting hostPackages replaces the module default, so re-list the
      # essentials and add Nix plus the niks3 client for cache pushes.
      hostPackages = with pkgs; [
        bash
        coreutils
        curl
        gawk
        git
        gnused
        nodejs
        wget
        nix
        inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.niks3
      ];
    };
  };

  sops.secrets.gitea-actions-runner-token = {
    sopsFile = ./secrets.yaml;
  };

  virtualisation.docker.enable = true;
}
