{ ... }:
{
  flake.modules.homeManager.git =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.programs.git;
      scalarCfg = config.programs.git.scalar;
    in
    {
      options.my.programs.git.enable = lib.mkEnableOption "git";

      options.programs.git.scalar = {
        enable = lib.mkEnableOption "scalar";

        repo = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "${config.home.homeDirectory}/NixOS/nixpkgs" ];
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          programs.git = {
            enable = true;

            settings = {
              user = {
                name = "natsukium";
                email = "tomoya.otabi@gmail.com";
              };
              core.editor = "vim";
              color = {
                status = "auto";
                diff = "auto";
                branch = "auto";
                interactive = "auto";
                grep = "auto";
              };
              init.defaultBranch = "main";
              push.useForceIfIncludes = true;
              url."git@github.com:".pushInsteadOf = "https://github.com/";
            };

            signing = {
              format = "ssh";
              key = "~/.ssh/id_ed25519.pub";
              signByDefault = true;
            };

            ignores = [
              ".DS_Store"
              ".aider*"
              ".direnv"
              ".envrc"
              ".ipynb_checkpoints"
              ".pre-commit-config.yaml"
              ".vscode/"
              "__pycache__/"
              ".worktree"
              ".private/"
            ];

            scalar = {
              enable = true;
              repo = [ "${config.programs.git.settings.ghq.root}/github.com/natsukium/nixpkgs" ];
            };
          };

          programs.gh.enable = true;

          programs.delta = {
            enable = true;
            enableGitIntegration = true;
          };

          programs.difftastic = {
            enable = true;
          };

          programs.lazygit = {
            enable = true;
            settings = {
              gui = {
                showIcons = true;
              };

              git = {
                overrideGpg = true;
                pagers = [
                  {
                    colorArg = "always";
                    pager = "delta --dark --paging=never";
                  }
                  {
                    externalDiffCommand = "difft --color=always";
                  }
                ];
              };
            };
          };

          programs.fish.shellAbbrs = {
            gpf = "git push --force-with-lease";
            gpm = "git pull (git remote show origin | sed -n '/HEAD branch/s/.*: //p')";
            gpu = "git pull upstream";
            gci = "git commit ";
            gca = "git commit --amend";
            gs = "git status";
            gst = "git stash";
            gstp = "git stash pop";
            gsw = "git switch";
            gswc = "git switch -c";
          };
        })

        (lib.mkIf scalarCfg.enable {
          programs.git.settings = {
            scalar.repo = scalarCfg.repo;
            core = {
              multipackindex = true;
              preloadindex = true;
              untrackedcache = true;
              autocrlf = false;
              safecrlf = false;
              fsmonitor = true;
            };
            am.keepcr = true;
            credential = {
              "https://dev.azure.com".usehttppath = true;
              validate = false;
            };
            gc.auto = 0;
            gui.gcwarning = false;
            index = {
              threads = true;
              version = 4;
            };
            merge = {
              stat = false;
              renames = true;
            };
            pack = {
              usebitmaps = false;
              usesparse = true;
            };
            receive.autogc = false;
            feature = {
              manyfiles = false;
              experimental = false;
            };
            fetch = {
              unpacklimit = 1;
              writecommitgraph = false;
              showforcedupdates = false;
            };
            status.aheadbehind = false;
            commitgraph.generationversion = 1;
            log.excludedecoration = "refs/prefetch/*";
            maintenance = {
              repo = scalarCfg.repo;
              auto = false;
              strategy = "incremental";
            };
          };
        })
      ];
    };
}
