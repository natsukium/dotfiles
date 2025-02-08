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
            url = "https://github.com/natsukium/PaperWM.spoon/commit/6c78cfc737ee1c6f27b313a45798f20ea6af0f0e.patch";
            hash = "sha256-eCTLX8IueMhIt741+KPOapYsgqET3qf/XP/YbmNi8Wg=";
          })
        ];
      }))
    ];
  };
}
