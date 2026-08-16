# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.nixos.forgejo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.forgejo;
    in
    {
      options.my.services.forgejo.enable = lib.mkEnableOption "my forgejo instance";

      config = lib.mkIf cfg.enable {
        services.forgejo = {
          enable = true;
          package = pkgs.forgejo;
          database.type = "postgres";
          settings = {
            service.DISABLE_REGISTRATION = true;
            server = {
              HTTP_PORT = 3010;
              SSH_PORT = lib.head config.services.openssh.ports;
              DOMAIN = "git.natsukium.com";
              ROOT_URL = "https://git.natsukium.com/";
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

          ${lib.getExe config.services.forgejo.package} admin user create \
            --username renovate \
            --email "renovate@natsukium.com" \
            --password "$(tr -d '\n' < ${config.sops.secrets.forgejo-renovate-password.path})" \
            --must-change-password=false || true
        '';

        sops.secrets.forgejo-admin-password = {
          sopsFile = ./secrets.yaml;
          owner = "forgejo";
        };

        sops.secrets.forgejo-renovate-password = {
          sopsFile = ./secrets.yaml;
          owner = "forgejo";
        };

        my.services.cloudflared-tunnel.ingress.${config.services.forgejo.settings.server.DOMAIN} =
          let
            inherit (config.services.forgejo.settings.server) HTTP_ADDR HTTP_PORT;
          in
          {
            service = "http://${toString HTTP_ADDR}:${toString HTTP_PORT}";
          };

        services.postgresqlBackup = {
          enable = true;
          databases = [ config.services.forgejo.database.name ];
        };

        my.services.restic.backups.forgejo.paths = [
          config.services.forgejo.stateDir
          "${config.services.postgresqlBackup.location}/${config.services.forgejo.database.name}.sql.gz"
        ];
      };
    };
}
