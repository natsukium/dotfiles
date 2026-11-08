# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
{
  flake.modules.homeManager.plamo-translate =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.plamo-translate;

      inherit (inputs.pyproject-build-systems.inputs) pyproject-nix uv2nix;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      fixups =
        final: prev:
        let
          linkMlx =
            drv:
            drv.overrideAttrs (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.darwin.autoSignDarwinBinariesHook ];
              postFixup = (old.postFixup or "") + ''
                find $out -name '*.so' -print0 | while IFS= read -r -d "" f; do
                  otool -L "$f" | grep -q @rpath/libmlx.dylib || continue
                  install_name_tool -add_rpath ${final.mlx-metal}/${final.python.sitePackages}/mlx/lib "$f"
                done
              '';
            });
        in
        {
          mlx = linkMlx prev.mlx;
          vllm-metal = (linkMlx prev.vllm-metal).overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              patch -d $out/${final.python.sitePackages} -p1 < ${./vllm-metal-plamo3.patch}
            '';
          });
          mlx-lm = prev.mlx-lm.overrideAttrs (old: {
            nativeBuildInputs =
              old.nativeBuildInputs
              ++ final.resolveBuildSystem {
                setuptools = [ ];
                setuptools-scm = [ ];
              };
            SETUPTOOLS_SCM_PRETEND_VERSION = old.version;
          });
          mlx-vlm = prev.mlx-vlm.overrideAttrs (old: {
            nativeBuildInputs =
              old.nativeBuildInputs
              ++ final.resolveBuildSystem {
                setuptools = [ ];
                wheel = [ ];
              };
          });
        };

      pythonSet =
        (pkgs.callPackage pyproject-nix.build.packages { python = pkgs.python312; }).overrideScope
          (
            lib.composeManyExtensions [
              inputs.pyproject-build-systems.overlays.default
              (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
              fixups
            ]
          );

      env = pythonSet.mkVirtualEnv "plamo-translate-env" workspace.deps.default;

      weights = {
        repo = "pfnet/plamo-3-translate-2b-MLX-4bit";
        rev = "63777ddc6dc80aacacd92a1bf6966105f2f6270c";
      };
      source = {
        repo = "pfnet/plamo-3-translate-2b";
        rev = "355637cc04db67195ba87a97da85eaf1d52a22e8";
      };

      maxModelLen = 4096;
      kvBytesPerToken = 24 * 2 * 4 * 128 * 2;

      serve = pkgs.writeShellApplication {
        name = "plamo-translate-serve";
        runtimeInputs = [
          env
          pkgs.jq
          pkgs.patch
        ];
        text = ''
          model="''${XDG_DATA_HOME:-$HOME/.local/share}/plamo-translate/${weights.rev}"
          if [ ! -e "$model/config.json" ]; then
            weights=$(hf download ${weights.repo} --revision ${weights.rev} --quiet)
            source=$(hf download ${source.repo} --revision ${source.rev} --quiet \
              config.json modeling_plamo.py)
            mkdir -p "$(dirname "$model")"
            tmp=$(mktemp -d "$model.XXXXXX")
            ln -s "$weights"/* "$tmp"/
            rm "$tmp/config.json"
            jq --slurpfile src "$source/config.json" \
              '.auto_map = $src[0].auto_map | .model_file = "plamo3_fast.py"' \
              "$weights/config.json" > "$tmp/config.json"
            cp "$source/modeling_plamo.py" "$tmp"/
            cp "$weights/modeling_plamo_mlx.py" "$tmp/plamo3_fast.py"
            patch -d "$tmp" -p1 < ${./plamo3-fast.patch}
            mv "$tmp" "$model"
          fi
          exec vllm serve "$model" \
            --trust-remote-code \
            --host ${cfg.host} \
            --port ${toString cfg.port} \
            --served-model-name plamo-3-translate-2b \
            --max-model-len ${toString maxModelLen} \
            --max-num-seqs ${toString cfg.maxNumSeqs} \
            --kv-cache-memory-bytes ${toString (cfg.maxNumSeqs * maxModelLen * kvBytesPerToken)}
        '';
      };

      log = "${config.home.homeDirectory}/Library/Logs/plamo-translate.log";
    in
    {
      options.my.services.plamo-translate = {
        enable = lib.mkEnableOption "PLaMo 3 Translate served by vllm-metal";
        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 8002;
        };
        maxNumSeqs = lib.mkOption {
          type = lib.types.ints.positive;
          default = 16;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
            message = "plamo-translate runs on vllm-metal, which needs Apple silicon";
          }
        ];

        launchd.agents.plamo-translate = {
          enable = true;
          config = {
            ProgramArguments = [ (lib.getExe serve) ];
            EnvironmentVariables = {
              DO_NOT_TRACK = "1";
              HF_HUB_DISABLE_TELEMETRY = "1";
              VLLM_NO_USAGE_STATS = "1";
            };
            KeepAlive = true;
            RunAtLoad = true;
            ProcessType = "Background";
            StandardOutPath = log;
            StandardErrorPath = log;
          };
        };
      };
    };
}
