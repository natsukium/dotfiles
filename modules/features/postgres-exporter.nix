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
          # Run as the postgres system user so peer auth on the local socket
          # logs in as the superuser role. This reaches every database in the
          # cluster (pg_stat_database is cluster-wide) without provisioning a
          # monitoring role or storing a password: the default dataSourceName
          # already points at the /run/postgresql socket as user=postgres.
          runAsLocalSuperUser = true;
        };

        services.prometheus.scrapeConfigs = [
          {
            job_name = "postgres";
            static_configs = [ { targets = [ "127.0.0.1:${toString exporter.port}" ]; } ];
          }
        ];
      };
    };
}
