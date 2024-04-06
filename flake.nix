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
    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.base16-schemes = {
        url = "github:tinted-theming/base16-schemes";
        flake = false;
      };
    };
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
    };
    nur.url = "github:nix-community/nur";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
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
    {
      nixpkgs,
      home-manager,
      darwin,
      nix-colors,
      nur,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      homeConfigurations =
        let
          conf =
            username:
            home-manager.lib.homeManagerConfiguration {
              pkgs = import nixpkgs { system = "x86_64-linux"; };
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
              "${host}" = darwin.lib.darwinSystem {
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
          mikumi = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [ ./nix/systems/darwin/mikumi.nix ];
            specialArgs = {
              inherit inputs;
              username = "natsukium";
            };
          };
        };
      nixosConfigurations = {
        kilimanjaro = nixpkgs.lib.nixosSystem {
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
        arusha = nixpkgs.lib.nixosSystem {
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
        serengeti = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./nix/homes/nixos/serengeti
            ./nix/systems/nixos/serengeti
          ];
          specialArgs = {
            inherit inputs;
            username = "gazelle";
          };
        };
        # main server (mini pc)
        manyara = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nix/systems/nixos/manyara ];
          specialArgs = {
            inherit inputs;
            username = "natsukium";
          };
        };
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nurpkgs = import nur {
            inherit pkgs;
            nurpkgs = import nixpkgs { inherit system; };
          };
        in
        {
          default = import ./shell.nix { inherit pkgs nurpkgs; };
        }
      );
    };
}
