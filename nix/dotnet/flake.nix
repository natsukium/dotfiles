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
          packageName = "dotnet-dev";
        in
          {
            packages.${packageName} = pkgs.dotnet-sdk_5;
            defaultPackage = self.packages.${system}.${packageName};

            devShell = pkgs.mkShell {
              buildInputs = with pkgs; [ dotnet-sdk_5 ];
              inputsFrom = builtins.attrValues self.packages.${system};
              shellHook = ''
                export NUGET_PACKAGES=$XDG_CACHE_HOME/NuGetPackages
              '';
            };
          }
    );
}
