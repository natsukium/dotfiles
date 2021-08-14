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
          packageName = "python-dev";
        in
          {
            packages.${packageName} = pkgs.python39;
            defaultPackage = self.packages.${system}.${packageName};

            devShell = pkgs.mkShell {
              buildInputs = with pkgs; [ python39 python39Packages.poetry ];
              inputsFrom = builtins.attrValues self.packages.${system};
              shellHook = ''
                export POETRY_HOME=$XDG_DATA_HOME/poetry
                export POETRY_VIRTUALENVS_IN_PROJECT=true
                export IPYTHONDIR=$XDG_CONFIG_HOME/jupyter
                export JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter
              '';
            };
          }
    );
}
