{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
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
    darwin,
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
            ./nix/homes/common.nix
            {
              targets.genericLinux.enable = true;
              home = {
                username = "gazelle";
                homeDirectory = "/home/gazelle";
              };
              nixpkgs.config.allowUnfreePredicate = pkg: true;
            }
          ];
          extraSpecialArgs = {
            isWsl = false;
            inherit inputs;
          };
        };

        githubActions =
          home-manager.lib.homeManagerConfiguration
          {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
            };
            modules = [
              ./nix/homes/common.nix
              {
                targets.genericLinux.enable = true;
                home = {
                  username = "runner";
                  homeDirectory = "/home/runner";
                };
                nixpkgs.config.allowUnfreePredicate = pkg: true;
              }
            ];
            extraSpecialArgs = {
              isWsl = false;
              inherit inputs;
            };
          };
      };
      darwinConfigurations = {
        macbook =
          darwin.lib.darwinSystem
          {
            system = "x86_64-darwin";
            modules = [
              ./nix/systems/darwin.nix
              home-manager.darwinModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users."tomoya.matsumoto" = import ./nix/homes/darwin.nix;
                  backupFileExtension = "backup";
                  extraSpecialArgs = {
                    isWsl = false;
                    inherit inputs;
                  };
                };
                users.users."tomoya.matsumoto".home = "/Users/tomoya.matsumoto";
                nix.settings = {
                  substituters = ["https://cache.nixos.org" "https://natsukium.cachix.org"];
                  trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="];
                  trusted-users = ["root" "@wheel"];
                };
                homebrew = {
                  enable = true;
                  brews = [
                    "libomp"
                  ];
                  casks = [
                    "clipy"
                    "google-japanese-ime"
                    "vivaldi"
                  ];
                };
              }
            ];
            specialArgs = {inherit inputs;};
          };

        githubActions = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./nix/systems/darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                users.runner = import ./nix/homes/common.nix;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  isWsl = false;
                  inherit inputs;
                };
              };
              users.users.runner.home = "/Users/runner";
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
                users.gazelle = import ./nix/homes/nixos-wsl.nix;
                extraSpecialArgs = {
                  isWsl = true;
                  inherit inputs;
                };
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
