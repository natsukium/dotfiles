{ pkgs, config, ... }:
let
  lua = pkgs.lua5_4.withPackages (ps: with ps; [ luautf8 ]);
in
{
  xdg.configFile."sketchybar/sketchybarrc" = {
    source = pkgs.substituteAll {
      src = ./sketchybarrc;
      inherit lua;
      inherit (pkgs) sbarlua;
    };
    executable = true;
  };
  xdg.configFile."sketchybar/colors.lua" = {
    source = pkgs.substituteAll {
      src = ./colors.lua;
      inherit (config.colorScheme.palette)
        base00
        base01
        base02
        base03
        base04
        base05
        base06
        base07
        base08
        base09
        base0A
        base0B
        base0C
        base0D
        base0E
        base0F
        ;
    };
  };
  xdg.configFile."sketchybar/init.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.programs.git.extraConfig.ghq.root}/github.com/natsukium/dotfiles/applications/sketchybar/init.lua";
  xdg.configFile."sketchybar/items" = {
    source = ./items;
    recursive = true;
  };
}
