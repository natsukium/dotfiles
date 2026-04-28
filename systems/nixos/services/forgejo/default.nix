{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    database.type = "postgres";
    settings = {
      service.DISABLE_REGISTRATION = true;
      server = {
        HTTP_PORT = 3010;
        DOMAIN = "git.natsukium.com";
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

  services.cloudflared.tunnels.${config.my.services.cloudflared-tunnel.id}.ingress.${config.services.forgejo.settings.server.DOMAIN} =
    let
      inherit (config.services.forgejo.settings.server) HTTP_ADDR HTTP_PORT;
    in
    {
      service = "http://${toString HTTP_ADDR}:${toString HTTP_PORT}";
    };

  sops.secrets.forgejo-admin-password = {
    sopsFile = ./secrets.yaml;
    owner = "forgejo";
  };
}
