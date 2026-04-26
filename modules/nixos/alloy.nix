{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.alloy;
in
{
  options.my.services.alloy = {
    enable = lib.mkEnableOption "Grafana Alloy log shipper";
    configs = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Alloy config snippets keyed by name. Each entry is materialized as
        /etc/alloy/<name>.alloy and picked up by the upstream services.alloy
        unit.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.alloy.enable = true;
    environment.etc = lib.mapAttrs' (
      name: text: lib.nameValuePair "alloy/${name}.alloy" { inherit text; }
    ) cfg.configs;
  };
}
