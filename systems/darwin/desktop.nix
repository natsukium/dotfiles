{
  lib,
  pkgs,
  config,
  specialArgs,
  ...
}:
let
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
          [ "${pkgs.zen-browser}/Applications/Zen.app" ]
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
    pkgs.moralerspace-hw
  ];

  my.services.google-japanese-input = {
    enable = true;
    package = pkgs.brewCasks.google-japanese-ime.overrideAttrs (oldAttrs: {
      src = pkgs.fetchurl {
        url = oldAttrs.src.url;
        hash = "sha256-j6vXsk9x7QphwKqFcgTzX+s7yR6ImcAjxhTxkpIUUgc=";
      };
      unpackPhase = ''
        runHook preUnpack

        undmg $src
        mv GoogleJapaneseInput.pkg GoogleJapaneseInputOrig.pkg
        xar -xf GoogleJapaneseInputOrig.pkg
        rm GoogleJapaneseInputOrig.pkg
        pushd GoogleJapaneseInput.pkg
        zcat Payload | cpio -i
        popd

        runHook postUnpack
      '';

      nativeBuildInputs = with pkgs; [
        cpio
        undmg
        xar
      ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r GoogleJapaneseInput.pkg/{Applications,Library} $out

        runHook postInstall
      '';

      postFixup = ''
        substituteInPlace $out/Library/LaunchAgents/com.google.inputmethod.Japanese.Converter.plist \
          --replace-fail "/Library" "$out/Library"
        substituteInPlace $out/Library/LaunchAgents/com.google.inputmethod.Japanese.Renderer.plist \
          --replace-fail "/Library" "$out/Library"
      '';
    });
  };

  services.sketchybar.enable = true;
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
