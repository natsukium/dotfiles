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
            url = "https://github.com/natsukium/PaperWM.spoon/commit/51397007ee99e59c9ce365f8b90dd91b28027aa1.patch";
            hash = "sha256-3Cpv0lS5F24Y6SbHsHa1BJfqIUGyDXUGLxaUxN7BoCY=";
          })
        ];
      }))
    ];
  };
}
