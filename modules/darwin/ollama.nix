{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression types;

  cfg = config.services.ollama;

  ollamaEnvironment = cfg.environmentVariables // {
    HOME = cfg.home;
    OLLAMA_MODELS = cfg.models;
    OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
  };
in
{
  options.services.ollama = {
    enable = lib.mkEnableOption "ollama server for local large language models";
    package = lib.mkPackageOption pkgs "ollama" { };

    home = lib.mkOption {
      type = types.str;
      default = "/var/lib/ollama";
      description = ''
        The home directory that the ollama service is started in.
      '';
    };
    models = lib.mkOption {
      type = types.str;
      default = "${cfg.home}/models";
      defaultText = literalExpression ''"''${config.services.ollama.home}/models"'';
      example = "/path/to/ollama/models";
      description = ''
        The directory that the ollama service will read models from
        and download new models to.
      '';
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "[::]";
      description = ''
        The host address which the ollama server HTTP interface listens to.
      '';
    };
    port = lib.mkOption {
      type = types.port;
      default = 11434;
      example = 11111;
      description = ''
        Which port the ollama server listens to.
      '';
    };

    environmentVariables = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        OLLAMA_LLM_LIBRARY = "cpu";
      };
      description = ''
        Set arbitrary environment variables for the ollama service.

        Be aware that these are only seen by the ollama server (launchd daemon),
        not normal invocations like `ollama run`. Since `ollama run` is mostly
        a shell around the ollama server, this is usually sufficient.
      '';
    };
    loadModels = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Download these models using `ollama pull` once the ollama daemon has started.

        Search for models of your choice from: <https://ollama.com/library>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.ollama = {
      serviceConfig = {
        ProgramArguments = [
          (lib.getExe cfg.package)
          "serve"
        ];
        EnvironmentVariables = ollamaEnvironment;
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "/var/log/ollama.log";
        StandardErrorPath = "/var/log/ollama.err.log";
      };
    };

    launchd.daemons.ollama-model-loader = lib.mkIf (cfg.loadModels != [ ]) {
      script = ''
        until ${lib.getExe cfg.package} list >/dev/null 2>&1; do
          sleep 2
        done

        failed=0
        for model in ${lib.escapeShellArgs cfg.loadModels}; do
          ${lib.getExe cfg.package} pull "$model" &
        done
        for job in $(jobs -p); do
          wait "$job" || failed=$((failed + 1))
        done

        [ "$failed" -eq 0 ] || { echo "error: $failed model downloads failed" >&2; exit 1; }
      '';
      serviceConfig = {
        EnvironmentVariables = ollamaEnvironment;
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        ThrottleInterval = 30;
        StandardOutPath = "/var/log/ollama-model-loader.log";
        StandardErrorPath = "/var/log/ollama-model-loader.err.log";
      };
    };
  };
}
