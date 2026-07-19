{ ... }:
{
  flake.modules.nixos.prometheus =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.prometheus;
      linux-machines = inputs.self.outputs.nixosConfigurations;
      darwin-machines = inputs.self.outputs.darwinConfigurations;

      # Every host enables the node exporter, so enablement cannot pick the ones
      # worth scraping: it would add the laptops, which are off far more than on
      # and would only contribute failed scrapes.
      nodeMetricsHosts = [
        "manyara"
        "serengeti"
        "mikumi"
        "kilimanjaro"
      ];
    in
    {
      options.my.services.prometheus.enable = mkEnableOption "Prometheus metrics server";

      config = mkIf cfg.enable {
        services.prometheus = {
          enable = true;
          scrapeConfigs = [
            {
              job_name = "node";
              # A single group, because listing a host under more than one meant
              # scraping it twice: every series it produced was stored once per
              # role label, so anything reading them counted a single fault as
              # several.
              static_configs = [
                {
                  targets = lib.mapAttrsToList (
                    name: value:
                    let
                      inherit (value.config.services.prometheus.exporters.node) listenAddress port;
                    in
                    "${if name == config.networking.hostName then listenAddress else name}:${toString port}"
                  ) (lib.filterAttrs (n: _: builtins.elem n nodeMetricsHosts) (linux-machines // darwin-machines));
                }
              ];
            }
          ];
        };
      };
    };
}
