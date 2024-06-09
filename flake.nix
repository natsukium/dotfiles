{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

      flake = {
        homeConfigurations =
          let
            conf =
              username:
              self.inputs.home-manager.lib.homeManagerConfiguration {
                pkgs = import self.inputs.nixpkgs { system = "x86_64-linux"; };
                modules = [ ./nix/homes/non-nixos/common.nix ];
                extraSpecialArgs = {
                  inherit inputs;
                  username = username;
                };
              };
          in
          {
            x64-vm = conf "gazelle";
          };
        darwinConfigurations =
          let
            conf =
              {
                host,
                username,
                system ? "aarch64-darwin",
              }:
              {
                "${host}" = self.inputs.darwin.lib.darwinSystem {
                  inherit system;
                  modules = [
                    ./nix/systems/darwin/${host}.nix
                    ./nix/homes/darwin/${host}.nix
                  ];
                  specialArgs = {
                    inherit inputs username;
                  };
                };
              };
          in
          conf {
            host = "work";
            username = "tomoya.matsumoto";
          }
          // conf {
            # main laptop (m1 macbook air)
            host = "katavi";
            username = "gazelle";
          }
          // {
            # build server (m1 mac mini)
            mikumi = self.inputs.darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = [ ./nix/systems/darwin/mikumi.nix ];
              specialArgs = {
                inherit inputs;
                username = "natsukium";
              };
            };
          };
        nixosConfigurations = {
          kilimanjaro = self.inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./nix/homes/nixos/kilimanjaro
              ./nix/systems/nixos/kilimanjaro
            ];
            specialArgs = {
              inherit inputs;
              username = "natsukium";
            };
          };
          arusha = self.inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./nix/homes/nixos/arusha.nix
              ./nix/systems/nixos/arusha
            ];
            specialArgs = {
              inherit inputs;
              username = "gazelle";
            };
          };
          serengeti = self.inputs.nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./nix/systems/nixos/serengeti ];
            specialArgs = {
              inherit inputs;
              username = "natsukium";
            };
          };
          # main server (mini pc)
          manyara = self.inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./nix/systems/nixos/manyara ];
            specialArgs = {
              inherit inputs;
              username = "natsukium";
            };
          };
        };

        nixOnDroidConfigurations = {
          default = self.inputs.nix-on-droid.lib.nixOnDroidConfiguration {
            system = "aarch64-linux";
            modules = [
              ./nix/systems/nix-on-droid
              ./nix/homes/nix-on-droid
            ];
            extraSpecialArgs = {
              inherit inputs;
            };
          };
        };
      };

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import self.inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.inputs.nur-packages.overlays.default ];
          };

          devShells = {
            default = import ./shell.nix { inherit pkgs; };
          };
        };
    };
}
