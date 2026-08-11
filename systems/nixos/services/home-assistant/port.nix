{ lib, ... }:
{
  # Home Assistant 2026.8 moved its HTTP settings out of configuration.yaml and
  # into the frontend, so nixpkgs dropped
  # services.home-assistant.config.http.server_port and the port can no longer be
  # read back from the module. The Caddy vhost and the VictoriaMetrics scrape
  # target both need it, so it is declared once here rather than repeated as a
  # literal.
  options.my.services.home-assistant.port = lib.mkOption {
    type = lib.types.port;
    default = 8123;
    description = ''
      Port the Home Assistant frontend listens on, which is upstream's default
      for an instance with no HTTP settings configured. Home Assistant owns the
      setting now, so this only points the reverse proxy and the VictoriaMetrics
      scrape target at it: change the port under Settings -> System -> Network
      and then match it here by hand.
    '';
  };
}
