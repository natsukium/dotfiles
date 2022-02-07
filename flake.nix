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
                };
                users.users."tomoya.matsumoto".home = "/Users/tomoya.matsumoto";
                services.nix-daemon.enable = true;
              }
            ];
          };
      };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell
          {
            nativeBuildInputs = with pkgs; [ checkbashisms rnix-lsp shellcheck ];
            shellHook = ''
              '';
          };
      });
}
