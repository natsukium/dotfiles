{ config, ... }:
{
  services.gitea-actions-runner = {
    instances.default = {
      enable = true;
      name = config.networking.hostName;
      url = "https://git.natsukium.com";
      tokenFile = config.sops.secrets.gitea-actions-runner-token.path;
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
      ];
    };
  };

  sops.secrets.gitea-actions-runner-token = {
    sopsFile = ./secrets.yaml;
  };

  virtualisation.docker.enable = true;
}
