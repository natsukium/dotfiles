{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) username;
in {
  imports = [./common.nix];
  home-manager.users.${username} = {
    programs.git = {
      userName = pkgs.lib.mkForce "GitHub Actions";
      userEmail = pkgs.lib.mkForce "action@github.com";
    };
  };
}
