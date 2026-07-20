{
  config,
  inputs,
  ...
}:
let
  niks3Port = "5751";

  # Write path, through the tunnel. Only presigned-URL requests cross it; NARs
  # go straight to R2.
  serverDomain = "niks3.natsukium.com";

  # Read path: the public R2 bucket's custom domain, used as the substituter.
  # Pulls bypass the tunnel and the server entirely.
  cacheDomain = "nix-cache.natsukium.com";
in
{
  # Bootstrap (one-time, local). The R2 bucket and both domains are provisioned
  # by Terraform in infra/global/domains/natsukium-com.
  #
  # 1. nix key generate-secret --key-name niks3-1 > /tmp/niks3.key
  #    Add its `nix key convert-secret-to-public` output to trusted-public-keys
  #    in configuration.org and modules/configuration.org.
  # 2. openssl rand -base64 32                     # API token, >= 36 chars
  # 3. Create an R2 API token (read/write) in the Cloudflare dashboard; the
  #    Terraform provider cannot mint these.
  # 4. sops ./secrets.yaml with niks3-api-token, niks3-signing-key (the full
  #    /tmp/niks3.key), niks3-s3-access-key, niks3-s3-secret-key.
  #
  # CI pushes via OIDC (GitHub and Forgejo Actions), so no push token is stored.

  imports = [ inputs.niks3.nixosModules.niks3 ];

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:${niks3Port}";

    database.createLocally = true;

    s3 = {
      endpoint = "dd87ce894022aec81eacd8ff1948438e.r2.cloudflarestorage.com";
      bucket = "nix-cache-niks3";
      region = "auto";
      useSSL = true;
      accessKeyFile = config.sops.secrets.niks3-s3-access-key.path;
      secretKeyFile = config.sops.secrets.niks3-s3-secret-key.path;
    };

    apiTokenFile = config.sops.secrets.niks3-api-token.path;
    signKeyFiles = [ config.sops.secrets.niks3-signing-key.path ];

    cacheUrl = "https://${cacheDomain}";
    serverUrl = "https://${serverDomain}";

    gc.olderThan = "168h";

    oidc.providers = {
      github = {
        issuer = "https://token.actions.githubusercontent.com";
        audience = "https://${serverDomain}";
        boundClaims.repository = [ "natsukium/dotfiles" ];
      };
      forgejo = {
        issuer = "https://git.natsukium.com/api/actions";
        audience = "https://${serverDomain}";
        boundClaims.repository_owner = [ "natsukium" ];
      };
    };
  };

  my.services.cloudflared-tunnel.ingress.${serverDomain} = {
    service = "http://localhost:${niks3Port}";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "niks3";
      static_configs = [ { targets = [ "127.0.0.1:${niks3Port}" ]; } ];
    }
  ];

  sops.secrets = {
    niks3-api-token = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
    niks3-signing-key = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
    niks3-s3-access-key = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
    niks3-s3-secret-key = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
  };
}
