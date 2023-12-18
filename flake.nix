{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
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
      inputs.flake-utils.follows = "flake-utils";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.base16-schemes = {
        url = "github:tinted-theming/base16-schemes";
        flake = false;
      };
    };
    hyprland.url = "github:hyprwm/Hyprland";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nur.url = "github:nix-community/nur";
    nixbins = {
      url = "github:natsukium/nixbins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];

    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  outputs = {
    nixpkgs,
    home-manager,
    darwin,
    nix-colors,
    flake-utils,
    ...
  } @ inputs: let
    colorScheme = nix-colors.colorSchemes.nord;
  in
    {
      homeConfigurations = let
        conf = username:
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
            };
            modules = [
              ./nix/homes/non-nixos/common.nix
            ];
            extraSpecialArgs = {
              inherit inputs colorScheme;
              username = username;
            };
          };
      in {
        x64-vm = conf "gazelle";
        githubActions = conf "runner";
      };
      darwinConfigurations = let
        conf = {
          host,
          username,
          system ? "aarch64-darwin",
        }: {
          "${host}" = darwin.lib.darwinSystem {
            inherit system;
            modules = [
              ./nix/systems/darwin/${host}.nix
              ./nix/homes/darwin/${host}.nix
            ];
            specialArgs = {
              inherit inputs colorScheme username;
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
          githubActions = darwin.lib.darwinSystem {
            system = "x86_64-darwin";
            modules = [
              ./nix/systems/darwin/common.nix
              ./nix/homes/darwin/github-actions.nix
            ];
            specialArgs = {
              inherit inputs colorScheme;
              username = "runner";
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
            inherit inputs colorScheme;
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
            inherit inputs colorScheme;
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
            inherit inputs colorScheme;
            username = "gazelle";
          };
        };
        # main server (mini pc)
        manyara = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nix/systems/nixos/manyara
          ];
          specialArgs = {
            inherit inputs;
            username = "natsukium";
          };
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = let
        sketchybarrc = pkgs.python3Packages.callPackage ./nix/pkgs/sketchybarrc-py {};
        python-env = pkgs.python3.withPackages (ps: [sketchybarrc]);
      in
        pkgs.mkShell
        {
          nativeBuildInputs = with pkgs; [alejandra checkbashisms rnix-lsp shellcheck shfmt python-env];
          shellHook = ''
          '';
        };
    });
}
