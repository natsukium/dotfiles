# https://wiki.archlinux.org/title/XDG_Base_Directory
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ext.xdg;
in
{
  options.ext.xdg = {
    enable = mkEnableOption "enable additional XDG Base Directory support";
    aws-cli.enable = mkOption {
      type = types.bool;
      default = true;
    };
    cuda.enable = mkOption {
      type = types.bool;
      default = config.nixpkgs.config.cudaSupport or false;
    };
    docker.enable = mkOption {
      type = types.bool;
      default = true;
    };
    gpg.enable = mkOption {
      type = types.bool;
      default = true;
    };
    nodejs.enable = mkOption {
      type = types.bool;
      default = true;
    };
    ollama.enable = mkOption {
      type = types.bool;
      default = true;
    };
    parallel.enable = mkOption {
      type = types.bool;
      default = true;
    };
    python.enable = mkOption {
      type = types.bool;
      default = true;
    };
    rust.enable = mkOption {
      type = types.bool;
      default = true;
    };
    wakatime.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.aws-cli.enable {
      home.sessionVariables = {
        AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
        AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
      };
    })
    (mkIf cfg.cuda.enable {
      home.sessionVariables = {
        CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
      };
    })
    (mkIf cfg.docker.enable {
      home.sessionVariables = {
        DOCKER_CONFIG = "${config.xdg.configHome}/docker";
        MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
      };
    })
    (mkIf cfg.gpg.enable {
      programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";
    })
    (mkIf cfg.nodejs.enable {
      home.sessionVariables = {
        NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
        NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
      };
      xdg.configFile."npm/npmrc".source = ./npmrc;
    })
    (mkIf cfg.ollama.enable {
      home.sessionVariables = {
        OLLAMA_MODELS = "${config.xdg.dataHome}/ollama/models";
      };
    })
    (mkIf cfg.parallel.enable {
      home.sessionVariables = {
        PARALLEL_HOME = "${config.xdg.configHome}/parallel";
      };
    })
    (mkIf cfg.python.enable {
      home.sessionVariables = {
        PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonstartup";
        JUPYTER_PLATFORM_DIRS = 1;
      };
      home.sessionVariablesExtra = ''
        [ ! -f ${config.xdg.cacheHome}/python/history ] && mkdir -p ${config.xdg.cacheHome}/python && touch ${config.xdg.cacheHome}/python/history
      '';
      xdg.configFile."python/pythonstartup".source = ./pythonstartup;
    })
    (mkIf cfg.rust.enable {
      home.sessionVariables = {
        CARGO_HOME = "${config.xdg.dataHome}/cargo";
        RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
      };
    })
    (mkIf cfg.wakatime.enable {
      home.sessionVariables = {
        WAKATIME_HOME = "${config.xdg.configHome}/wakatime";
      };
      home.sessionVariablesExtra = ''
        [ ! -d ${config.xdg.configHome}/wakatime ] && mkdir ${config.xdg.configHome}/wakatime
      '';
    })
  ]);
}
