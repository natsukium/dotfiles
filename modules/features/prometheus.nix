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
    in
    {
      options.my.services.prometheus.enable = mkEnableOption "Prometheus metrics server";

      config = mkIf cfg.enable {
        services.prometheus = {
          enable = true;
          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [
                {
                  labels.role = "builders";
                  targets =
                    lib.mapAttrsToList
                      (
                        name: value:
                        let
                          inherit (value.config.services.prometheus.exporters.node) listenAddress port;
                        in
                        "${if name == config.networking.hostName then listenAddress else name}:${toString port}"
                      )
                      (
                        lib.filterAttrs (n: v: n == "kilimanjaro" || n == "serengeti" || n == "mikumi") (
                          linux-machines // darwin-machines
                        )
                      );
                }
                {
                  labels.role = "servers";
                  targets =
                    lib.mapAttrsToList
                      (
                        name: value:
                        let
                          inherit (value.config.services.prometheus.exporters.node) listenAddress port;
                        in
                        "${if name == config.networking.hostName then listenAddress else name}:${toString port}"
                      )
                      (
                        lib.filterAttrs (n: v: n == "kilimanjaro" || n == "manyara" || n == "serengeti") (
                          linux-machines // darwin-machines
                        )
                      );
                }
              ];
            }
          ];
        };
      };
    };
}
