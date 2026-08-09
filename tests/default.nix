{
  nixpkgs,
  pkgs,
  self,
  ...
}:
let
  nixos-lib = import "${nixpkgs}/nixos/lib" { };
in
{
  # Renovate's hash updater parses Nix expressions with regular expressions, so
  # its unit tests are what stands between a parsing regression and a wrong hash
  # committed to a pull request.
  update-nix-hash =
    (pkgs.callPackage ../modules/features/renovate/update-nix-hash.nix { }).tests.pytest;
}
// pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
  nixosModuleTests = nixos-lib.runTest {
    hostPkgs = pkgs;

    # Hand `self` to every node as a normal module argument, so test files stay
    # plain modules imported by path instead of each currying self in by hand.
    node.specialArgs = { inherit self; };

    imports = [
      ./nixos/calibre-web.nix
    ];
  };
}
