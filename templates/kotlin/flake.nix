{
  description = "Kotlin develop environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          packages = {
            default = config.packages.idea;
            idea = pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea-community [
              "ideavim"
            ];
          };

          devShells = {
            default = pkgs.mkShellNoCC {
              packages = [
                config.packages.idea
                pkgs.kotlin
              ];
            };
          };
        };
    };
}
