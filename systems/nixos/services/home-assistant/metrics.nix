{ config, ... }:
let
  # VictoriaMetrics runs under DynamicUser, so sops-nix has no stable account
  # to chown the secret to; LoadCredential hands it in with the secret itself
  # staying root-only. The literal path is safe to bake in because
  # bearer_token_file is opened at scrape time, not by the build-time check.
  tokenFile = "/run/credentials/victoriametrics.service/home-assistant-token";
in
{
  sops.secrets."home-assistant-prometheus-token" = {
    sopsFile = ./secrets.yaml;
    key = "prometheus-token";
  };

  systemd.services.victoriametrics.serviceConfig.LoadCredential = [
    "home-assistant-token:${config.sops.secrets."home-assistant-prometheus-token".path}"
  ];

  services.victoriametrics.prometheusConfig.scrape_configs = [
    {
      job_name = "home-assistant";
      metrics_path = "/api/prometheus";
      static_configs = [
        { targets = [ "127.0.0.1:${toString config.services.home-assistant.config.http.server_port}" ]; }
      ];
      bearer_token_file = tokenFile;
    }
  ];

  services.vmalert.instances.main.rules.groups = [
    {
      name = "home-assistant";
      rules = [
        {
          alert = "CatLitterBoxFull";
          # PetKit reports box-full as the binary_sensor *_wastebin_filled,
          # which reads 1 when full. Matched by entity-id suffix so the
          # device name isn't pinned; *_wastebin_presence is a different
          # sensor and the anchored suffix excludes it.
          expr = ''homeassistant_binary_sensor_state{entity=~".*_wastebin_filled"} == 1'';
          # A box briefly reads full right after use before the auto-clean
          # cycle; 30m waits out that transient so only a genuinely unemptied
          # bin notifies.
          for = "30m";
          labels.severity = "warning";
          annotations.summary = "Cat litter waste bin is full ({{ $labels.friendly_name }})";
        }
      ];
    }
  ];
}
