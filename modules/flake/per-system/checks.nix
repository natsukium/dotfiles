{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = import ../../../tests {
        inherit (inputs) nixpkgs;
        inherit pkgs;
      };
    };
}
