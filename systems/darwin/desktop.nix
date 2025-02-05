{ pkgs, config, ... }:
let
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
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0;
        };
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  fonts.packages = [
    pkgs.liga-hackgen-nf-font
    pkgs.moralerspace-hwnf
  ];

  homebrew.casks = [ "google-japanese-ime" ];

  services.sketchybar.enable = true;
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  security.pam.enableSudoTouchIdAuth = true;

  services.bclm = {
    enable = true;
    # remove the override if swift is fixed
    # https://github.com/NixOS/nixpkgs/issues/327836#issuecomment-2308417434
    package = pkgs.bclm.overrideAttrs { meta.broken = false; };
  };
}
