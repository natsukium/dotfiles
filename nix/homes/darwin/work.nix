{
  pkgs,
  config,
  specialArgs,
  ...
}: let
  inherit (specialArgs) username;
  nurpkgs = config.nur.repos.natsukium;
in {
  imports = [
    ./common.nix
  ];

  home-manager.users.${username} = {
    imports = [
      ../desktop.nix
      ../../applications/sketchybar
    ];
    home.packages = with pkgs; [
      monitorcontrol
      nurpkgs.nowplaying-cli
      raycast
    ];
  };
}
