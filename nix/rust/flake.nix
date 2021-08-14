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
          packageName = "rust-dev";
        in
          {
            packages.${packageName} = pkgs.rustup;
            defaultPackage = self.packages.${system}.${packageName};

            devShell = pkgs.mkShell {
              buildInputs = with pkgs; [ rustup ];
              inputsFrom = builtins.attrValues self.packages.${system};
              shellHook = ''
                export CARGO_HOME=$XDG_DATA_HOME/cargo
                export PATH=$CARGO_HOME/bin:$PATH
                export RUSTUP_HOME=$XDG_DATA_HOME/rustup
                rustup toolchain install stable
              '';
            };
          }
    );
}
