{
  lib,
  pkgs,
  config,
  specialArgs,
  ...
}:
let
  zen-browser' = (
    pkgs.zen-browser.overrideAttrs (_: {
      sourceRoot = "Zen Browser.app";
    })
  );
in
{
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
        persistent-apps =
          let
            inherit (config.home-manager.users.${specialArgs.username}) programs;
          in
          [ "${zen-browser'}/Applications/Zen.app" ]
          ++ lib.optional programs.kitty.enable "${programs.kitty.package}/Applications/kitty.app"
          ++ lib.optional programs.emacs.enable "${programs.emacs.package}/Applications/Emacs.app";
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

  my.services.google-japanese-input.enable = true;

  services.sketchybar.enable = true;
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  security.pam.enableSudoTouchIdAuth = true;
}
