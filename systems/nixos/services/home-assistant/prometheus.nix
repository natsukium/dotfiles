{ config, pkgs, ... }:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  sops.secrets."home-assistant-prometheus-token" = {
    sopsFile = ./secrets.yaml;
    key = "prometheus-token";
    owner = "prometheus";
  };

  # bearer_token_file points at a sops secret that only exists at runtime, but
  # the default build-time promtool check stats every referenced file and would
  # fail in the sandbox.
  services.prometheus.checkConfig = "syntax-only";

  services.prometheus.scrapeConfigs = [
    {
      job_name = "home-assistant";
      metrics_path = "/api/prometheus";
      static_configs = [
        { targets = [ "127.0.0.1:${toString config.services.home-assistant.config.http.server_port}" ]; }
      ];
      bearer_token_file = config.sops.secrets."home-assistant-prometheus-token".path;
    }
  ];

  services.prometheus.ruleFiles = [
    (yamlFormat.generate "home-assistant-rules.yaml" {
      groups = [
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
    })
  ];
}
