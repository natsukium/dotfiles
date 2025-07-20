{
  inputs,
  config,
  lib,
  ...
}:
let
  linux-machines = inputs.self.outputs.nixosConfigurations;
  darwin-machines = inputs.self.outputs.darwinConfigurations;
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "comin";
      static_configs = [
        {
          targets = lib.mapAttrsToList (
            name: value:
            let
              inherit (value.config.services.comin.exporter) listen_address port;
              listen_address' = if listen_address == "" then "localhost" else listen_address;
            in
            "${if name == config.networking.hostName then listen_address' else name}:${toString port}"
          ) (linux-machines // darwin-machines);
        }
      ];
    }
  ];
}
