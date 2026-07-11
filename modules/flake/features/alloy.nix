{ lib, ... }:
let
  # The nixos and darwin entries ship the same my.services.alloy interface but
  # materialize the configs differently per platform, so the option surface lives
  # here once (a new suboption reaches both classes) while each class keeps only
  # its own config body.
  options = {
    options.my.services.alloy = {
      enable = lib.mkEnableOption "Grafana Alloy log shipper";
      configs = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = ''
          Alloy config snippets keyed by name, loaded by the running service.
          The nixos entry materializes one /etc/alloy/<name>.alloy file per key;
          the darwin entry concatenates them into a single file passed on the
          launchd command line.
        '';
      };
    };
  };
in
{
  flake.modules.nixos.alloy =
    { config, ... }:
    let
      cfg = config.my.services.alloy;
    in
    options
    // {
      config = lib.mkIf cfg.enable {
        services.alloy.enable = true;
        environment.etc = lib.mapAttrs' (
          name: text: lib.nameValuePair "alloy/${name}.alloy" { inherit text; }
        ) cfg.configs;
      };
    };

  flake.modules.darwin.alloy =
    { config, pkgs, ... }:
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
    options
    // {
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
    };
}
