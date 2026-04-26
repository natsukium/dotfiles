{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.alloy;

  # Concatenate every config block into a single file passed on the launchd
  # command line. nix-darwin's environment.etc does not currently materialize
  # subdirectory entries through /etc/static/, so the upstream-style
  # /etc/alloy/ layout would leave the directory empty and Alloy would start
  # ready but with an empty pipeline.
  combinedConfig = lib.concatStringsSep "\n\n" (lib.attrValues cfg.configs);
  configFile = pkgs.writeText "alloy.alloy" combinedConfig;

  alloyDataDir = "/var/lib/alloy";
  alloyLogDir = "/var/log/alloy";
in
{
  options.my.services.alloy = {
    enable = lib.mkEnableOption "Grafana Alloy log shipper";
    configs = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Alloy config snippets keyed by name. All entries are concatenated
        into a single file passed to alloy on the launchd command line.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.grafana-alloy ];

    launchd.daemons.alloy = {
      serviceConfig = {
        Label = "com.dotfiles.alloy";
        ProgramArguments = [
          (lib.getExe pkgs.grafana-alloy)
          "run"
          "--storage.path=${alloyDataDir}"
          "${configFile}"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${alloyLogDir}/alloy.log";
        StandardErrorPath = "${alloyLogDir}/alloy.err.log";
      };
    };

    system.activationScripts.alloyDirs.text = ''
      mkdir -p ${alloyDataDir} ${alloyLogDir}
      chmod 755 ${alloyDataDir} ${alloyLogDir}
    '';
  };
}
