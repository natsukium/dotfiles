{ nixpkgs, pkgs, ... }:
let
  nixos-lib = import "${nixpkgs}/nixos/lib" { };
in
pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
  nixosModuleTests = nixos-lib.runTest {
    hostPkgs = pkgs;

    imports = [
      ./nixos/calibre-web.nix
    ];
  };
}
