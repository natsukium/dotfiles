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
            url = "https://github.com/natsukium/PaperWM.spoon/commit/125157f504d25c1abb29e1f4bc605d9ad492bdd1.patch";
            hash = "sha256-aRIoqhgjHjUtDDRQ310gUSzUV9GgeBKQotWs5EPkCgU=";
          })
        ];
      }))
    ];
  };
}
