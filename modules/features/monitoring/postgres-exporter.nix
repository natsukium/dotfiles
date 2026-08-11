{ ... }:
{
  flake.modules.nixos.postgres-exporter =
    { config, lib, ... }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.postgres-exporter;
      exporter = config.services.prometheus.exporters.postgres;
    in
    {
      options.my.services.postgres-exporter.enable =
        mkEnableOption "Prometheus exporter for the local PostgreSQL cluster";

      config = mkIf cfg.enable {
        services.prometheus.exporters.postgres = {
          enable = true;
          # Peer auth as the postgres user reaches every database in the
          # cluster without a monitoring role or a stored password; the
          # default dataSourceName already uses the local socket.
          runAsLocalSuperUser = true;
        };

        services.victoriametrics.prometheusConfig.scrape_configs = [
          {
            job_name = "postgres";
            static_configs = [ { targets = [ "127.0.0.1:${toString exporter.port}" ]; } ];
          }
        ];
      };
    };
}
