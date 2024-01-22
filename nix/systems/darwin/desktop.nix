{ pkgs, config, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  imports = [
    ../../applications/yabai
    ../../applications/skhd
    ../../modules/darwin/bclm.nix
    ../../modules/darwin/finder.nix
    ../../modules/services/copyq.nix
  ];

  system = {
    defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
      dock = {
        autohide = true;
        mru-spaces = false;
        orientation = "left";
        showhidden = true;
        show-recents = false;
        tilesize = 40;
        wvous-br-corner = 4;
        wvous-tl-corner = 10;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "clmv";
        FXRemoveOldTrashItems = true;
        ShowStatusBar = true;
      };
      CustomUserPreferences = {
        "com.apple.inputmethod.Kotoeri" = {
          JIMPrefLiveConversionKey = 0;
        };
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
  fonts = {
    fontDir.enable = true;
    fonts = [ nurpkgs.liga-hackgen-nf-font ];
  };

  homebrew.casks = [ "google-japanese-ime" ];

  services.sketchybar.enable = true;
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;
  services.copyq.enable = true;

  services.bclm = {
    enable = true;
    package = config.nur.repos.natsukium.bclm;
  };
}
