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
          packageName = "NodeJS-dev";
        in
          {
            packages.${packageName} = pkgs.nodejs-16_x;
            defaultPackage = self.packages.${system}.${packageName};

            devShell = pkgs.mkShell {
              buildInputs = with pkgs; [ nodejs-16_x yarn ];
              inputsFrom = builtins.attrValues self.packages.${system};
              shellHook = ''
                export NODE_REPL_HISTORY=$XDG_DATA_HOME/node_repl_history
                export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
                yarn set version berry
              '';
            };
          }
    );
}
