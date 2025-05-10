{ config, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    authKeyFile = config.sops.secrets.tailscale-authkey.path;
    extraUpFlags = [ "--ssh" ];
  };
  networking = {
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
    nameservers = [
      "100.100.100.100"
      "8.8.8.8"
    ];
    search = [ "tail4108.ts.net" ];
  };

  # address DNS issue
  # https://github.com/tailscale/tailscale/issues/4254
  services.resolved.enable = true;

  sops.secrets.tailscale-authkey = { };
}
