{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs) stdenv;
  agentUser = "${lib.optionalString stdenv.hostPlatform.isDarwin "_"}hercules-ci-agent";
in
{
  services.hercules-ci-agent = {
    enable = true;
    settings = {
      clusterJoinTokenPath = config.sops.secrets.hercules-ci-agent-token.path;
      binaryCachesPath = config.sops.secrets.binary-caches.path;
    };
  };

  sops.secrets.hercules-ci-agent-token = {
    sopsFile = ./secrets.yaml;
    owner = agentUser;
  };

  sops.secrets.binary-caches = {
    format = "json";
    sopsFile = ./binary-caches.json;
    owner = agentUser;
    key = "";
  };
}
