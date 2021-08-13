{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packageName = "nix-dev";
        in
          {
            packages.${packageName} = pkgs.rnix-lsp;
            defaultPackage = self.packages.${system}.${packageName};

            devShell = pkgs.mkShell {
              buildInputs = [ pkgs.rnix-lsp ];
              inputsFrom = builtins.attrValues self.packages.${system};
            };
          }
    );
}
