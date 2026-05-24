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
    microvm = {
      url = "github:astro/microvm.nix";
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
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.flake-parts.follows = "flake-parts";
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
    paneru = {
      url = "github:natsukium/paneru/fix/emacs-child-frame";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "darwin";
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
        ./modules/flake/features/neovim
        ./modules/flake/per-system/checks.nix
        ./modules/flake/per-system/dev-shell.nix
        ./modules/flake/per-system/mcp-servers.nix
        ./modules/flake/per-system/packages.nix
        ./modules/flake/per-system/pkgs.nix
        ./modules/flake/per-system/pre-commit.nix
        ./modules/flake/per-system/treefmt.nix
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
      };
    };
}
