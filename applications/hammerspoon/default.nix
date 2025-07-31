{ config, pkgs, ... }:
{
  my.services.hammerspoon = {
    enable = true;
    configFile = config.lib.file.mkOutOfStoreSymlink "${config.programs.git.extraConfig.ghq.root}/github.com/natsukium/dotfiles/applications/hammerspoon/init.lua";
    spoons = [
      (pkgs.paperwm-spoon.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch2 {
            name = "window-offset-support.patch";
            url = "https://github.com/natsukium/PaperWM.spoon/commit/b172a99fbf343bb356fe2debeb66a6eee2190570.patch";
            hash = "sha256-tV+N9TO0kXFFhPbrDq8pTcG5oDEh2BQy1qZ3ga2KL9s=";
          })
        ];
      }))
    ];
  };
}
