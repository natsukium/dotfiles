# https://wiki.archlinux.org/title/XDG_Base_Directory
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ext.xdg;
in {
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
    readline.enable = mkOption {
      type = types.bool;
      default = config.programs.readline.enable;
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
      programs.bash.profileExtra = ''
        export AWS_CONFIG_FILE=$XDG_CONFIG_HOME/aws/config
        export AWS_SHARED_CREDENTIALS_FILE=$XDG_CONFIG_HOME/aws/credentials
      '';
    })
    (mkIf cfg.cuda.enable {
      programs.bash.profileExtra = ''
        export CUDA_CACHE_PATH=$XDG_CACHE_HOME/nv
      '';
    })
    (mkIf cfg.docker.enable {
      programs.bash.profileExtra = ''
        export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker
        export MACHINE_STORAGE_PATH=$XDG_DATA_HOME/docker-machine
      '';
    })
    (mkIf cfg.nodejs.enable {
      programs.bash.profileExtra = ''
        export NODE_REPL_HISTORY=$XDG_DATA_HOME/node_repl_history
        export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
      '';
      xdg.configFile."npm/npmrc".source = ./npmrc;
    })
    (mkIf cfg.ollama.enable {
      programs.bash.profileExtra = ''
        export OLLAMA_MODELS=$XDG_DATA_HOME/ollama/models
      '';
    })
    (mkIf cfg.parallel.enable {
      programs.bash.profileExtra = ''
        export PARALLEL_HOME=$XDG_CONFIG_HOME/parallel
      '';
    })
    (mkIf cfg.python.enable {
      programs.bash.profileExtra = ''
        export PYTHONSTARTUP=$XDG_CONFIG_HOME/python/pythonstartup
        [ ! -f $XDG_CACHE_HOME/python/history ] && mkdir -p $XDG_CACHE_HOME/python && touch $XDG_CACHE_HOME/python/history
        export JUPYTER_PLATFORM_DIRS=1
      '';
      xdg.configFile."python/pythonstartup".source = ./pythonstartup;
    })
    (mkIf cfg.readline.enable {
      programs.bash.profileExtra = ''
        export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
      '';
    })
    (mkIf cfg.rust.enable {
      programs.bash.profileExtra = ''
        export CARGO_HOME=$XDG_DATA_HOME/cargo
        # export RUSTUP_HOME=$XDG_DATA_HOME/rustup
      '';
    })
    (mkIf cfg.wakatime.enable {
      programs.bash.profileExtra = ''
        [ ! -d $XDG_CONFIG_HOME/wakatime ] && mkdir $XDG_CONFIG_HOME/wakatime
        export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
      '';
    })
  ]);
}
