{ config, pkgs, ... }:
{
  my.services.hammerspoon = {
    enable = true;
    configFile = config.lib.file.mkOutOfStoreSymlink "${config.programs.git.settings.ghq.root}/github.com/natsukium/dotfiles/applications/hammerspoon/init.lua";
    spoons = [
      (pkgs.paperwm-spoon.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch2 {
            name = "window-offset-support.patch";
            url = "https://github.com/natsukium/PaperWM.spoon/commit/054011baf09079ae6e49c01fa8b04dacda98eca7.patch";
            hash = "sha256-1ps05ksquKq/rE7xJuxmL8EEx5aAqyB9E5HhxNCl6Hs=";
          })
        ];
      }))
    ];
  };
}
