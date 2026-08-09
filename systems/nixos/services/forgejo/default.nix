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
  '';

  # The repositories under stateDir are only half the instance: issues, pull
  # requests, users and access tokens all live in postgres, and a restore that
  # brings back one without the other leaves a Forgejo that cannot serve any of
  # it. Upstream's own `forgejo dump`, which services.forgejo.dump would
  # schedule, is not an alternative: it warns that the SQL dump it packs into
  # the zip "has serious long standing open bugs that may introduce problems
  # when re-injecting the SQL dump in a new database", and its nightly zip
  # would arrive as a fresh opaque blob every time, leaving restic nothing to
  # deduplicate against yesterday's.
  services.postgresqlBackup = {
    enable = true;
    databases = [ config.services.forgejo.database.name ];
  };

  my.services.restic.backups.forgejo.paths = [
    config.services.forgejo.stateDir
    "${config.services.postgresqlBackup.location}/${config.services.forgejo.database.name}.sql.gz"
  ];

  my.services.cloudflared-tunnel.ingress.${config.services.forgejo.settings.server.DOMAIN} =
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
