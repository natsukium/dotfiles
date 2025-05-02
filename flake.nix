{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-24.05";
    # see https://github.com/renovatebot/renovate/issues/29721
    # "github:NixOS/nixpkgs/trick-renovate-into-working"
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
    darwin.url = "github:lnl7/nix-darwin";
    disko.url = "github:nix-community/disko";
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
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nur-packages.url = "github:natsukium/nur-packages";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    tsnsrv.url = "github:boinkor-net/tsnsrv";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # used in follows
    flake-utils.url = "github:numtide/flake-utils";

    cachix-deploy-flake.inputs.darwin.follows = "darwin";
    cachix-deploy-flake.inputs.disko.follows = "disko";
    cachix-deploy-flake.inputs.home-manager.follows = "home-manager";
    cachix-deploy-flake.inputs.nixos-anywhere.follows = "";
    cachix-deploy-flake.inputs.nixpkgs.follows = "nixpkgs";
    claude-desktop.inputs.flake-utils.follows = "flake-utils";
    claude-desktop.inputs.nixpkgs.follows = "nixpkgs";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    git-hooks.inputs.flake-compat.follows = "";
    git-hooks.inputs.gitignore.follows = "";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.flake-compat.follows = "";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.pre-commit-hooks-nix.follows = "git-hooks";
    mcp-servers.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.inputs.niri-stable.follows = "";
    niri-flake.inputs.niri-unstable.follows = "";
    niri-flake.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.inputs.xwayland-satellite-stable.follows = "";
    niri-flake.inputs.xwayland-satellite-unstable.follows = "";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    nix-on-droid.inputs.nix-formatter-pack.follows = "";
    nix-on-droid.inputs.nixpkgs-docs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs-for-bootstrap.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
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
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
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
            overlays = [ self.inputs.nur-packages.overlays.default ] ++ builtins.attrValues self.overlays;
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
              fastfetch = pkgs.callPackage ./pkgs/fastfetch { };
              neovim = pkgs.callPackage ./pkgs/neovim-with-config { };
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
                  p.aws
                  p.cloudflare
                  p.external
                  p.github
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
