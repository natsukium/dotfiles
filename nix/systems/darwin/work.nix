{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./desktop.nix
  ];

  homebrew = {
    enable = true;
    brews = [ "libomp" ];
  };

  nix.extraOptions = ''
    ssl-cert-file = /Library/Application Support/Netskope/STAgent/download/nscacert.pem
  '';

  environment.variables = {
    REQUESTS_CA_BUNDLE = "/Library/Application Support/Netskope/STAgent/download/nscacert.pem";
    NODE_EXTRA_CA_CERTS = "/Library/Application Support/Netskope/STAgent/download/nscacert.pem";
  };
}
