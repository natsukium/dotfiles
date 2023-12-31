{
  pkgs,
  config,
  ...
}: let
  nurpkgs = config.nur.repos.natsukium;
in {
  imports = [
    ../../applications/sketchybar
    ../desktop.nix
  ];

  home.packages = with pkgs; [
    monitorcontrol
    nurpkgs.nowplaying-cli
    raycast
  ];
}
