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
    flake-utils.url = "github:numtide/flake-utils";
    nur.url = "github:nix-community/nur";
    nixbins = {
      url = "github:natsukium/nixbins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      darwinConfigurations = {
        work = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./nix/systems/darwin/work.nix
            ./nix/homes/darwin/work.nix
          ];
          specialArgs = {
            inherit inputs colorScheme;
            username = "tomoya.matsumoto";
          };
        };

        githubActions = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./nix/systems/darwin/common.nix
            ./nix/homes/darwin/common.nix
          ];
          specialArgs = {
            inherit inputs colorScheme;
            username = "runner";
          };
        };
      };
      nixosConfigurations = {
        arusha = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nix/homes/nixos/arusha.nix
            ./nix/systems/nixos/arusha.nix
          ];
          specialArgs = {
            inherit inputs colorScheme;
            username = "gazelle";
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
