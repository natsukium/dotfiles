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
    nixos-wsl = {
      url = github:nix-community/NixOS-WSL;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    flake-utils.url = github:numtide/flake-utils;
    nur.url = github:nix-community/NUR;
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nixos-wsl,
    flake-utils,
    ...
  } @ inputs: let
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
              nixpkgs.config.allowUnfreePredicate = pkg: true;
            }
          ];
        };

        githubActions =
          home-manager.lib.homeManagerConfiguration
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
                nixpkgs.config.allowUnfreePredicate = pkg: true;
              }
            ];
          };
      };
      darwinConfigurations = {
        macbook =
          nix-darwin.lib.darwinSystem
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
                nix.settings = {
                  substituters = ["https://cache.nixos.org" "https://natsukium.cachix.org"];
                  trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="];
                  trusted-users = ["root" "@wheel"];
                };
                nixpkgs.config.allowUnfree = true;
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
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
      };
      nixosConfigurations = {
        wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.wsl
            {imports = [./nix/systems/nixos-wsl.nix];}

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                users.gazelle = import ./nix/home.nix;
              };
              users.users.gazelle = {
                home = "/home/gazelle";
                isNormalUser = true;
                initialPassword = "";
                group = "wheel";
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu gazelle"
                ];
              };
            }
          ];
          specialArgs = {inherit inputs;};
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell =
        pkgs.mkShell
        {
          nativeBuildInputs = with pkgs; [alejandra checkbashisms rnix-lsp shellcheck shfmt];
          shellHook = ''
          '';
        };
    });
}
