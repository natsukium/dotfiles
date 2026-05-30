{ config, ... }:
let
  atticdPort = "8081";
in
{
  # Setup runbook for the `dotfiles` cache that CI pushes to.
  #
  # Tokens are split by privilege so the long-lived secret stored on GitHub
  # can only push/pull, never reconfigure or destroy a cache. atticd-atticadm
  # must run on the host (it reads the server signing key from the env file).
  #
  # 1. Bootstrap token (full privileges, run locally once, do NOT store):
  #    sudo atticd-atticadm make-token \
  #      --validity "1 hour" --sub "admin-bootstrap" \
  #      --pull "dotfiles" --push "dotfiles" \
  #      --create-cache "dotfiles" --configure-cache "dotfiles"
  #
  # 2. Create the cache and make it public so machines pull anonymously
  #    (only substituter URL + trusted-public-key needed, no per-host login):
  #    attic login natsukium https://cache.natsukium.com <bootstrap-token>
  #    attic cache create dotfiles
  #    attic cache configure dotfiles --public
  #
  # 3. Read the public key and add it to nix.settings.trusted-public-keys in
  #    modules/configuration.org (Binary Caches section):
  #    attic cache info dotfiles   # -> dotfiles:....=
  #
  # 4. CI token (push/pull only, least privilege) -> GitHub ATTIC_TOKEN secret:
  #    sudo atticd-atticadm make-token \
  #      --validity "1 year" --sub "github-ci-dotfiles" \
  #      --pull "dotfiles" --push "dotfiles"
  #    gh secret set ATTIC_TOKEN   # paste the token above

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets.atticd.path;
    settings = {
      listen = "[::]:${atticdPort}";
      chunking = {
        nar-size-threshold = 256 * 1024;
        min-size = 64 * 1024;
        avg-size = 256 * 1024;
        max-size = 1024 * 1024;
      };
      storage = {
        type = "s3";
        region = "";
        bucket = "nix-cache";
        endpoint = "https://dd87ce894022aec81eacd8ff1948438e.r2.cloudflarestorage.com";
      };
      garbage-collection = {
        default-retention-period = "7 days";
      };
    };
  };

  my.services.cloudflared-tunnel.ingress."cache.natsukium.com" = {
    service = "http://localhost:${atticdPort}";
  };

  sops.secrets.atticd = {
    sopsFile = ./secrets.yaml;
  };
}
