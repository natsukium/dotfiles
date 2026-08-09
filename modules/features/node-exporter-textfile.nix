{ ... }:
{
  flake.modules.nixos.node-exporter-textfile =
    { config, lib, ... }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        types
        ;
      cfg = config.my.services.node-exporter-textfile;
      exporter = config.services.prometheus.exporters.node;
    in
    {
      # Shared because more than one module publishes here, and the collector is
      # configured by a single-valued flag: a copy per publisher would put the
      # same flag on the command line twice and node_exporter refuses to start.
      options.my.services.node-exporter-textfile = {
        enable = mkEnableOption "the node exporter's textfile collector";

        directory = mkOption {
          type = types.path;
          default = "/var/lib/node-exporter-textfile";
          description = "Directory whose *.prom files the node exporter republishes.";
        };
      };

      config = mkIf cfg.enable {
        services.prometheus.exporters.node.extraFlags = [
          "--collector.textfile.directory=${cfg.directory}"
        ];

        systemd.tmpfiles.rules = [
          "d ${cfg.directory} 0700 ${exporter.user} ${exporter.group} -"
        ];
      };
    };
}
