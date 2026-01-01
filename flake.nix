# This file is auto-generated from configuration.org.
# Do not edit directly.

{
  description = "dotfiles";

  inputs = {
    # Core
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-25.05";
    # Flake Infrastructure
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # Transitive Dependencies
    flake-utils.url = "github:numtide/flake-utils";
    # System Configuration
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.flake-compat.follows = "";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.home-manager.follows = "home-manager";
      inputs.nix-formatter-pack.follows = "";
      inputs.nixpkgs-docs.follows = "nixpkgs";
      inputs.nixpkgs-for-bootstrap.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nmd.follows = "";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit.follows = "git-hooks";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    # Infrastructure
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Development Tools
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.flake-compat.follows = "";
      inputs.gitignore.follows = "";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Desktop & Theming
    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-wallpaper = {
      url = "github:natsukium/nix-wallpaper/custom-logo";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks.follows = "git-hooks";
    };
    # Applications
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nix-darwin.follows = "darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    edgepkgs = {
      url = "github:natsukium/edgepkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.niri-stable.follows = "";
      inputs.niri-unstable.follows = "";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.xwayland-satellite-stable.follows = "";
      inputs.xwayland-satellite-unstable.follows = "";
    };
    nur-packages = {
      url = "github:natsukium/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-wol-manager = {
      url = "git+https://git.natsukium.com/natsukium/simple-wol-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://natsukium.cachix.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="
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
        inputs.mcp-servers.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      hosts = {
        katavi = {
          system = "aarch64-darwin";
        };
        mikumi = {
          system = "aarch64-darwin";
        };
        work = {
          system = "aarch64-darwin";
        };
        kilimanjaro = {
          system = "x86_64-linux";
        };
        arusha = {
          system = "x86_64-linux";
        };
        manyara = {
          system = "x86_64-linux";
        };
        serengeti = {
          system = "aarch64-linux";
        };
        tarangire = {
          system = "x86_64-linux";
        };
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
          self',
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import self.inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.inputs.nur-packages.overlays.default ] ++ builtins.attrValues self.overlays;
          };

          checks = import ./tests {
            inherit (self.inputs) nixpkgs;
            inherit pkgs;
          };

          packages = {
            fastfetch = pkgs.callPackage ./pkgs/fastfetch { };
            neovim = pkgs.callPackage ./pkgs/neovim-with-config { };
            po4a_0_74 = (
              pkgs.po4a.overrideAttrs (oldAttrs: {
                version = "0.74";
                src = pkgs.fetchurl {
                  url = "https://github.com/mquinson/po4a/releases/download/v0.74/po4a-0.74.tar.gz";
                  hash = "sha256-JfwyPyuje71Iw68Ov0mVJkSw5GgmH5hjPpEhmoOP58I=";
                };
                patches = [ ];
                nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.libxml2 ];
                doCheck = false;
              })
            );
            html =
              with pkgs;
              let
                org-html-themes = fetchurl {
                  url = "https://raw.githubusercontent.com/fniessen/org-html-themes/b3898f4c5b09b3365fd93fd1566f46ecd0a8911f/org/theme-readtheorg.setup";
                  hash = "sha256-+5gy+S6NcuvlV61fudbCNoCKmSrCdA9P5CHeGKlDrSM=";
                };
                org-to-html = writeScript "org-to-html.el" ''
                  (require 'org)
                  (require 'htmlize)

                  (find-file "README.org")
                  (org-html-export-to-html)

                  (find-file "README.ja.org")
                  (org-html-export-to-html)
                '';
              in
              stdenvNoCC.mkDerivation {
                name = "dotfiles";
                src = lib.cleanSource ./.;
                postPatch = ''
                  substituteInPlace README.org \
                    --replace-fail "https://fniessen.github.io/org-html-themes/org/theme-readtheorg.setup" "${org-html-themes}"
                '';
                nativeBuildInputs = [
                  (emacs.pkgs.withPackages (epkgs: [ epkgs.htmlize ]))
                  gettext
                  self'.packages.po4a_0_74
                ];
                buildPhase = ''
                  runHook preBuild
                  po4a po4a.cfg
                  emacs --batch -l ${org-to-html}
                  runHook postBuild
                '';

                installPhase = ''
                  runHook preInstall
                  install -Dm644 README.html $out/index.html
                  install -Dm644 README.ja.html $out/ja/index.html
                  runHook postInstall
                '';
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
                    "homes/shared/gpg/keys.txt"
                    "secrets.yaml"
                    "secrets/default.yaml"
                    "systems/nixos/tarangire/facter.json"
                    "systems/shared/hercules-ci/binary-caches.json"
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
                # Prefixed with "00-" to ensure this hook runs before all other hooks
                # (hooks are sorted alphabetically when no explicit before/after is specified)
                "00-check-org-tangle" = {
                  enable = true;
                  name = "check-org-tangle";
                  description = "Verify org files are tangled and synchronized";
                  entry =
                    let
                      checkScript = pkgs.writeShellScript "check-org-tangle" ''
                        set -euo pipefail

                        ${pkgs.gnumake}/bin/make -B tangle

                        # Check for differences using git diff
                        changed=$(${pkgs.git}/bin/git diff --name-only)

                        if [ -n "$changed" ]; then
                          echo "Org files were out of sync and have been auto-tangled."
                          echo "Changed files:"
                          echo "$changed"
                          echo ""
                          echo "Please stage the changes and commit again:"
                          echo "  git add $changed"
                          exit 1
                        fi

                        exit 0
                      '';
                    in
                    "${checkScript}";
                  files = "\\.org$";
                  pass_filenames = false;
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

          mcp-servers = {
            flavors.claude-code.enable = true;
            programs = {
              nixos.enable = true;
              terraform.enable = true;
              grafana = {
                enable = true;
                env = {
                  GRAFANA_URL = "http://manyara:3001";
                  GRAFANA_USERNAME = "admin";
                };
                passwordCommand = {
                  GRAFANA_PASSWORD = [
                    "rbw"
                    "get"
                    "grafana"
                  ];
                };
              };
            };
          };

          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                gettext
                nix-fast-build
                self'.packages.po4a_0_74
                sops
                ssh-to-age
                (terraform.withPlugins (p: [
                  p.carlpett_sops
                  p.cloudflare_cloudflare
                  p.determinatesystems_hydra
                  p.hashicorp_aws
                  p.hashicorp_external
                  p.hashicorp_null
                  p.integrations_github
                  p.oracle_oci
                ]))
              ];
              shellHook =
                config.pre-commit.installationScript
                + config.mcp-servers.shellHook
                + ''
                  echo "Syncing CLAUDE.md..."
                  make CLAUDE.md >/dev/null 2>&1 || echo "Warning: Failed to generate CLAUDE.md"
                '';
            };
          };
        };
    };
}
