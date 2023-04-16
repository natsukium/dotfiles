{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs;
  nurpkgs =
    (import inputs.nur {
      inherit pkgs;
      nurpkgs = pkgs;
    })
    .repos
    .natsukium;
in {
  imports = [
    ./common.nix
    ../../applications/yabai
    ../../applications/skhd
    ../../modules/services/sketchybar.nix
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
    fonts = [nurpkgs.liga-hackgen-nf-font];
  };

  homebrew = {
    enable = true;
    brews = [
      "libomp"
    ];
    casks = [
      "google-japanese-ime"
    ];
  };

  services.sketchybar.enable = true;
  services.copyq.enable = true;
}
