{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-25.05";
    # see https://github.com/renovatebot/renovate/issues/29721
    # "github:NixOS/nixpkgs/trick-renovate-into-working"
    brew-api.flake = false;
    brew-api.url = "github:BatteredBunny/brew-api";
    brew-nix.url = "github:BatteredBunny/brew-nix";
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
    comin.url = "github:nlewo/comin";
    darwin.url = "github:nix-darwin/nix-darwin";
    disko.url = "github:nix-community/disko";
    edgepkgs.url = "github:natsukium/edgepkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager";
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";
    mcp-servers.url = "github:natsukium/mcp-servers-nix";
    niri-flake.url = "github:sodiboo/niri-flake";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-on-droid.url = "github:nix-community/nix-on-droid";
    nix-wallpaper.url = "github:natsukium/nix-wallpaper/custom-logo";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nur-packages.url = "github:natsukium/nur-packages";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    tsnsrv.url = "github:boinkor-net/tsnsrv";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # used in follows
    flake-utils.url = "github:numtide/flake-utils";

    brew-nix.inputs.brew-api.follows = "brew-api";
    brew-nix.inputs.nix-darwin.follows = "darwin";
    brew-nix.inputs.nixpkgs.follows = "nixpkgs";
    claude-desktop.inputs.flake-utils.follows = "flake-utils";
    claude-desktop.inputs.nixpkgs.follows = "nixpkgs";
    comin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    edgepkgs.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    git-hooks.inputs.flake-compat.follows = "";
    git-hooks.inputs.gitignore.follows = "";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.pre-commit.follows = "git-hooks";
    mcp-servers.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.inputs.niri-stable.follows = "";
    niri-flake.inputs.niri-unstable.follows = "";
    niri-flake.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.inputs.xwayland-satellite-stable.follows = "";
    niri-flake.inputs.xwayland-satellite-unstable.follows = "";
    nix-colors.inputs.nixpkgs-lib.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    nix-on-droid.inputs.nix-formatter-pack.follows = "";
    nix-on-droid.inputs.nixpkgs-docs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs-for-bootstrap.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nmd.follows = "";
    nix-wallpaper.inputs.flake-utils.follows = "flake-utils";
    nix-wallpaper.inputs.nixpkgs.follows = "nixpkgs";
    nix-wallpaper.inputs.pre-commit-hooks.follows = "git-hooks";
    nixos-wsl.inputs.flake-compat.follows = "";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nur-packages.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    tsnsrv.inputs.flake-parts.follows = "flake-parts";
    tsnsrv.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.home-manager.follows = "home-manager";
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
        # laptop for work (m4 macbook pro)
        work = {
          system = "aarch64-darwin";
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
        # build server (Ryzen 9 9950X)
        tarangire = {
          system = "x86_64-linux";
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
              shellHook = config.pre-commit.installationScript + ''
                echo "Syncing CLAUDE.md..."
                make CLAUDE.md >/dev/null 2>&1 || echo "Warning: Failed to generate CLAUDE.md"
              '';
            };
          };
        };
    };
}
