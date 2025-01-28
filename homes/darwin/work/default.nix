{ specialArgs, pkgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [ ../desktop.nix ];
    home.packages = [ pkgs.google-chrome ];
  };
}
