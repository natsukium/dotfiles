{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nur-packages = {
      url = "github:natsukium/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.git-hooks.follows = "git-hooks";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wallpaper = {
      url = "github:natsukium/nix-wallpaper/custom-logo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    cachix-deploy-flake = {
      url = "github:cachix/cachix-deploy-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks-nix.follows = "git-hooks";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flake-module.nix
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      hosts = {
        # main laptop (m1 macbook air)
        katavi = {
          system = "aarch64-darwin";
        };
        # build server (m1 mac mini)
        mikumi = {
          system = "aarch64-darwin";
        };
        # laptop for work (m1 macbook pro)
        work = {
          system = "aarch64-darwin";
          username = "tomoya.matsumoto";
        };
        # main desktop (intel core i5-12400F)
        kilimanjaro = {
          system = "x86_64-linux";
        };
        # WSL (dualboot with kilimanjaro)
        arusha = {
          system = "x86_64-linux";
        };
        # main server (intel N100)
        manyara = {
          system = "x86_64-linux";
        };
        # build server (OCI A1 Flex)
        serengeti = {
          system = "aarch64-linux";
        };
        # phone (pixel 7a)
        android = {
          system = "aarch64-linux";
          platform = "android";
        };
      };

      flake = {
        overlays = import ./overlays { inherit inputs; };
        templates = import ./templates;
      };

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import self.inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.inputs.nur-packages.overlays.default ];
          };

          checks = import ./tests {
            inherit (self.inputs) nixpkgs;
            inherit pkgs;
          };

          packages =
            let
              cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
            in
            {
              cachix-deploy = cachix-deploy-lib.spec {
                agents = {
                  mikumi = self.darwinConfigurations.mikumi.config.system.build.toplevel;
                };
              };
            };

          pre-commit = {
            check.enable = true;
            settings = {
              src = ./.;
              hooks = {
                actionlint.enable = true;
                biome.enable = true;
                lua-ls.enable = false;
                nil.enable = true;
                shellcheck.enable = true;
                treefmt.enable = true;
                typos = {
                  enable = true;
                  excludes = [
                    "secrets/default.yaml"
                    "secrets.yaml"
                  ];
                  settings.configPath = "typos.toml";
                };
                yamllint = {
                  enable = true;
                  excludes = [
                    "secrets/default.yaml"
                    "secrets.yaml"
                  ];
                  settings.configData = "{rules: {document-start: {present: false}}}";
                };
              };
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              biome.enable = true;
              nixfmt.enable = true;
              shfmt.enable = true;
              stylua.enable = true;
              taplo.enable = true;
              terraform.enable = true;
              yamlfmt.enable = true;
            };
          };

          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                nix-fast-build
                sops
                ssh-to-age
                (terraform.withPlugins (p: [
                  p.external
                  p.hydra
                  p.null
                  p.oci
                  p.sops
                ]))
              ];
              shellHook = config.pre-commit.installationScript;
            };
          };
        };
    };
}
