{ config, pkgs, ... }:
let
  # Custom components must be built against home-assistant's own Python interpreter
  # so that propagated Python deps line up with the rest of the HA wrapper.
  homeAssistantPyPkgs = config.services.home-assistant.package.python.pkgs;
  pypetkitapi = homeAssistantPyPkgs.callPackage ./pypetkitapi.nix { };
  sdp-transform = homeAssistantPyPkgs.callPackage ./sdp-transform.nix { };
  petkit = homeAssistantPyPkgs.callPackage ./petkit.nix {
    inherit (pkgs) buildHomeAssistantComponent;
    inherit pypetkitapi sdp-transform;
  };
in
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
    customComponents = [ petkit ];
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
