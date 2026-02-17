{ pkgs, specialArgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/base.nix
      ../../../modules/profiles/home/desktop.nix
      ../../../modules/profiles/home/development.nix
      ../desktop.nix
    ];
  };
}
