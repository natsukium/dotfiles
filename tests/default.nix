{ nixpkgs, pkgs, ... }:
let
  nixos-lib = import "${nixpkgs}/nixos/lib" { };
in
{
  nixosModuleTests = nixos-lib.runTest {
    hostPkgs = pkgs;

    imports = [
      ./nixos/calibre-web.nix
    ];
  };
}
