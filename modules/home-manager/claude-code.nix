{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.claude-code;

  settingsFormat = pkgs.formats.json { };

  settingsFile = settingsFormat.generate "settings.json" cfg.settings;
in
{
  options.my.programs.claude-code = {
    enable = lib.mkEnableOption "claude-code";

    package = lib.mkPackageOption pkgs "claude-code" { };

    userMemory = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Content for the User memory file (~/.claude/CLAUDE.md) with custom instructions.";
    };

    enableTelemetry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable OpenTelemetry metrics and events collection.";
    };

    otelMetricsExporter = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "otlp"
          "prometheus"
          "console"
        ]
      );
      default = null;
      description = "OpenTelemetry metrics exporter to use.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
        options = {
          apiKeyHelper = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Custom script path to generate an auth value.";
          };

          cleanupPeriodDays = lib.mkOption {
            type = lib.types.int;
            default = 30;
            description = "How long to locally retain chat transcripts in days.";
          };

          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = {
              OPENAI_API_KEY = "sk-...";
            };
            description = "Environment variables that will be applied to every session.";
          };

          includeCoAuthoredBy = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to include 'co-authored-by Claude' byline in commits.";
          };

          permissions = lib.mkOption {
            type = lib.types.submodule {
              options = {
                allow = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  example = [
                    "file:read"
                    "file:write"
                    "bash"
                  ];
                  description = "List of permitted actions.";
                };

                deny = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  example = [ "file:write:/etc/*" ];
                  description = "List of blocked actions.";
                };
              };
            };
            default = { };
            description = "Permission rules for claude-code operations.";
          };
        };
      };
      default = { };
      description = "Settings for claude-code.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    my.programs.claude-code.settings = lib.mkMerge [
      (lib.mkIf cfg.enableTelemetry {
        env.CLAUDE_CODE_ENABLE_TELEMETRY = "1";
      })
      (lib.mkIf (cfg.otelMetricsExporter != null) {
        env.OTEL_METRICS_EXPORTER = cfg.otelMetricsExporter;
      })
    ];

    home.file.".claude/settings.json" = lib.mkIf (cfg.settings != { }) {
      source = settingsFile;
    };

    home.file.".claude/CLAUDE.md" = lib.mkIf (cfg.userMemory != null) {
      text = cfg.userMemory;
    };
  };
}
