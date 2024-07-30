{ pkgs, lib, ... }:
let
  netskope-cert-file = "/Library/Application Support/Netskope/STAgent/download/nscacert.pem";
in
{
  imports = [
    ../common.nix
    ../desktop.nix
  ];

  homebrew = {
    enable = true;
    brews = [ "libomp" ];
    casks = [ "pritunl" ];
  };

  nix.extraOptions = ''
    ssl-cert-file = ${netskope-cert-file}
  '';

  environment.variables = builtins.listToAttrs (
    lib.lists.forEach
      [
        "CURL_CA_BUNDLE"
        "NODE_EXTRA_CA_CERTS"
        "REQUESTS_CA_BUNDLE"
      ]
      (x: {
        name = x;
        value = netskope-cert-file;
      })
  );
}
