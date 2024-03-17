{ pkgs, config, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  imports = [
    ../../applications/yabai
    ../../applications/skhd
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

  security.pam.enableSudoTouchIdAuth = true;

  services.bclm = {
    # reenable when https://github.com/NixOS/nixpkgs/pull/296082 is merged
    enable = false;
    package = config.nur.repos.natsukium.bclm;
  };
}
