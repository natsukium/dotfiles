{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = github:lnl7/nix-darwin;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, flake-utils, ... }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems (system: f system);
    in
    {
      homeConfigurations = {
        x64-vm = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          modules = [
            ./nix/home.nix
            {
              home = {
                username = "gazelle";
                homeDirectory = "/home/gazelle";
              };
            }
          ];
        };

        githubActions = home-manager.lib.homeManagerConfiguration
          {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
            };
            modules = [
              ./nix/home.nix
              {
                home = {
                  username = "runner";
                  homeDirectory = "/home/runner";
                };
              }
            ];
          };
      };
      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem
          {
            system = "x86_64-darwin";
            modules = [
              home-manager.darwinModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users."tomoya.matsumoto" = import ./nix/home.nix;
                  backupFileExtension = "backup";
                };
                users.users."tomoya.matsumoto".home = "/Users/tomoya.matsumoto";
                services.nix-daemon.enable = true;
                homebrew = {
                  enable = true;
                  brews = [
                    "libomp"
                  ];
                  casks = [
                    "clipy"
                    "google-japanese-ime"
                    "monitorcontrol"
                    "vivaldi"
                  ];
                };
              }
            ];
          };

        githubActions = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                users.runner = import ./nix/home.nix;
                backupFileExtension = "backup";
              };
              users.users.runner.home = "/Users/runner";
              services.nix-daemon.enable = true;
            }
          ];
        };
      };
    } //
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          devShell = pkgs.mkShell
            {
              nativeBuildInputs = with pkgs; [ checkbashisms rnix-lsp shellcheck shfmt ];
              shellHook = ''
              '';
            };
        });
}
