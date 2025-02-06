{ pkgs, ... }:
let
  inherit (pkgs) stdenv;
in
{
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    # workaround for https://github.com/LnL7/nix-darwin/pull/1319
    systems = [ stdenv.hostPlatform.system ];
  };
}
