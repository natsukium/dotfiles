{ config, inputs, ... }:
let
  inherit (inputs) attic;
in
{
  imports = [ attic.nixosModules.atticd ];

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
    credentialsFile = config.sops.secrets.atticd.path;
    settings = {
      listen = "[::]:8081";
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

  sops.secrets.atticd = {
    sopsFile = ./secrets.yaml;
  };
}
