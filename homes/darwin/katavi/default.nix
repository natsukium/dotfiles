{ pkgs, specialArgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/base.nix
      ../desktop.nix
    ];
  };
}
