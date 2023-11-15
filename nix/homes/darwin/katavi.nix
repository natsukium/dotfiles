{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) username;
in {
  imports = [
    ./common.nix
  ];

  home-manager.users.${username} = {
    imports = [
      ./desktop.nix
    ];
  };
}
