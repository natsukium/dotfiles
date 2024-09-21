{ config, lib, ... }:
{
  services.forgejo = {
    enable = true;
    database.type = "postgres";
    settings = {
      service.DISABLE_REGISTRATION = true;
      server = {
        HTTP_PORT = 3010;
      };
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
    };
  };

  systemd.services.forgejo.preStart = ''
    ${lib.getExe config.services.forgejo.package} admin user create \
      --username natsukium \
      --email "tomoya.otabi@gmail.com" \
      --password "$(tr -d '\n' < ${config.sops.secrets.forgejo-admin-password.path})" || true
  '';

  sops.secrets.forgejo-admin-password = {
    sopsFile = ./secrets.yaml;
    owner = "forgejo";
  };
}
