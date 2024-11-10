{ nixpkgs, pkgs, ... }:
let
  nixos-lib = import "${nixpkgs}/nixos/lib" { };
in
pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
  nixosModuleTests = nixos-lib.runTest {
    hostPkgs = pkgs;

    imports = [
      ./nixos/calibre-web.nix
    ];
  };
}
