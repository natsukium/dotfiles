# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
let
  mkBuilderModule =
    upstreamModule:
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.hydra;
    in
    {
      imports = [ upstreamModule ];

      options.my.services.hydra = {
        queueRunner = {
          enable = lib.mkEnableOption "the Hydra queue runner service";

          hostname = lib.mkOption {
            type = lib.types.str;
            default = "kilimanjaro";
            description = "Hostname builder agents use to reach the Hydra queue runner.";
          };

          restPort = lib.mkOption {
            type = lib.types.port;
            default = 24050;
            description = "Port for the queue runner REST API.";
          };

          grpcPort = lib.mkOption {
            type = lib.types.port;
            default = 24051;
            description = "Port for queue runner connections from builder agents.";
          };
        };

        builder = {
          enable = lib.mkEnableOption "the Hydra builder agent";

          queueRunnerAddress = lib.mkOption {
            type = lib.types.str;
            default = "http://${
              if cfg.queueRunner.enable then "localhost" else cfg.queueRunner.hostname
            }:${toString cfg.queueRunner.grpcPort}";
            defaultText = lib.literalExpression ''
              "http://''${
                if config.my.services.hydra.queueRunner.enable then
                  "localhost"
                else
                  config.my.services.hydra.queueRunner.hostname
              }:''${toString config.my.services.hydra.queueRunner.grpcPort}"
            '';
            description = "gRPC address of the Hydra queue runner.";
          };

          maxJobs = lib.mkOption {
            type = lib.types.ints.positive;
            default = if builtins.isInt config.nix.settings.max-jobs then config.nix.settings.max-jobs else 4;
            defaultText = lib.literalExpression ''
              if builtins.isInt config.nix.settings.max-jobs then config.nix.settings.max-jobs else 4
            '';
            description = "Maximum concurrent jobs accepted by this builder.";
          };

          speedFactor = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.ints.positive
              lib.types.float
            ];
            default = 1;
            description = "Relative scheduling speed of this builder.";
          };

          systems = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Systems advertised by this builder, or null to read them from Nix.";
          };

          supportedFeatures = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Features advertised by this builder, or null to read them from Nix.";
          };

          mandatoryFeatures = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Features required by every build assigned to this builder.";
          };
        };
      };

      config = lib.mkIf cfg.builder.enable {
        services.hydra-queue-builder-dev = {
          enable = true;
          queueRunnerAddr = cfg.builder.queueRunnerAddress;
          settings = {
            inherit (cfg.builder)
              mandatoryFeatures
              maxJobs
              speedFactor
              supportedFeatures
              systems
              ;
          };
        };
      };
    };

  queueRunnerModule =
    { config, lib, ... }:
    let
      cfg = config.my.services.hydra.queueRunner;
    in
    {
      config = lib.mkIf cfg.enable {
        services.hydra-queue-runner-dev = {
          enable = true;
          # The firewall only admits gRPC through the trusted Tailscale interface,
          # so application-level TLS would duplicate the tailnet's authenticated transport.
          grpc = {
            address = "[::]";
            port = cfg.grpcPort;
          };
          rest.port = cfg.restPort;
          settings = {
            machineFreeFn = "DynamicWithMaxJobLimit";
            useSubstitutes = true;
          };
        };

        services.hydra-dev.extraConfig = ''
          queue_runner_endpoint = http://localhost:${toString cfg.restPort}
        '';
      };
    };
in
{
  flake.modules.nixos.hydra.imports = [
    (mkBuilderModule inputs.hydra.nixosModules.hydra)
    queueRunnerModule
  ];
  flake.modules.darwin.hydra = mkBuilderModule inputs.hydra.darwinModules.builder;
}
