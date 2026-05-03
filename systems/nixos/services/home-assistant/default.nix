{ config, ... }:
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "met"
      "switchbot"
      "switchbot_cloud"
      "ecovacs"
    ];
    config = {
      homeassistant = {
        name = "Home";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
    };
  };

  services.caddy.virtualHosts."http://ha.home.natsukium.com".extraConfig = ''
    reverse_proxy localhost:${toString config.services.home-assistant.config.http.server_port}
  '';

  # The SwitchBot BLE integration scans for devices through BlueZ on the host.
  hardware.bluetooth.enable = true;
}
