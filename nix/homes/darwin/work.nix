{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs username;
  nurpkgs =
    (import inputs.nur {
      inherit pkgs;
      nurpkgs = pkgs;
    })
    .repos
    .natsukium;
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
