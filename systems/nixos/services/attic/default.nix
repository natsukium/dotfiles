{ config, ... }:
let
  atticdPort = "8081";
in
{
  # to create the token, run the following command
  # sudo atticd-atticadm make-token \
  #   --validity "10 years" \
  #   --sub "nixpkgs" \
  #   --pull "nixpkgs" \
  #   --push "nixpkgs" \
  #   --create-cache "nixpkgs" \
  #   --configure-cache "nixpkgs" \
  #   --configure-cache-retention "nixpkgs" \
  #   --destroy-cache "nixpkgs"

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
