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
        # Forgejo's builtin SSH server avoids colliding with Tailscale SSH on
        # port 22 (tailscaled intercepts tailnet IP :22 and skips OpenSSH's
        # authorized_keys flow, which the forced `forgejo serv` command relies
        # on). Reachability is gated by the host firewall — only tailscale0 is
        # in trustedInterfaces, so this stays tailnet-internal.
        START_SSH_SERVER = true;
        SSH_PORT = 2222;
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
