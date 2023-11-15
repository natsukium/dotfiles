{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs;
  nurpkgs =
    (import inputs.nur {
      inherit pkgs;
      nurpkgs = pkgs;
    })
    .repos
    .natsukium;
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
