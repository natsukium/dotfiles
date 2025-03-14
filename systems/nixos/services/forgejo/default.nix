{ config, lib, ... }:
{
  services.forgejo = {
    enable = true;
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

  services.cloudflared =
    let
      inherit (config.services.forgejo.settings.server) DOMAIN HTTP_ADDR HTTP_PORT;
    in
    {
      tunnels = {
        "acfc103f-c6b4-4cef-8269-e1985b80e1ac" = {
          credentialsFile = config.sops.secrets.cloudflared-tunnel.path;
          ingress = {
            "${DOMAIN}" = {
              service = "http://${toString HTTP_ADDR}:${toString HTTP_PORT}";
            };
          };
          default = "http_status:404";
        };
      };
    };

  sops.secrets.forgejo-admin-password = {
    sopsFile = ./secrets.yaml;
    owner = "forgejo";
  };

  sops.secrets.cloudflared-tunnel = {
    sopsFile = ./secrets.yaml;
  };
}
