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

  sops.secrets.tailscale-authkey = { };
}
