{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.google-japanese-input;
in
{
  options = {
    my.services.google-japanese-input = {
      enable = lib.mkEnableOption "google-japanese-input";
      package = lib.mkPackageOption pkgs "google-japanese-input" { };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];

        # FIXME: This is a workaround to avoid the following error
        # GoogleJapaneseInput[2588:20231] [_IMKServerLegacy _createConnection] could not register com.google.inputmethod.Japanese_Connection
        # GoogleJapaneseInput[2588:20231] [_IMKServerLegacy initWithName:bundleIdentifier:]: [IMKServer _createConnection]: *Failed* to register NSConnection name=com.google.inputmethod.Japanese_Connection
        # need to remove the packages from `/Library/Input Method` when disabling the service
        system.activationScripts.extraActivation.text = ''
          echo "copying google-japanese-input into /Library/Input Methods..."
          if [ -d "/Library/Input Methods/GoogleJapaneseInput.app" ]; then
            rm -r /Library/Input\ Methods/GoogleJapaneseInput.app
          fi
          cp -r ${cfg.package}/Library/Input\ Methods /Library/
        '';

        environment.userLaunchAgents = {
          "com.google.inputmethod.Japanese.Converter.plist".source =
            "${cfg.package}/Library/LaunchAgents/com.google.inputmethod.Japanese.Converter.plist";
          "com.google.inputmethod.Japanese.Renderer.plist".source =
            "${cfg.package}/Library/LaunchAgents/com.google.inputmethod.Japanese.Renderer.plist";
        };

        system.defaults.CustomUserPreferences = {
          "com.apple.inputsources" = {
            AppleEnabledThirdPartyInputSources = [
              {
                "Bundle ID" = "com.google.inputmethod.Japanese";
                InputSourceKind = "Keyboard Input Method";
              }
              {
                "Bundle ID" = "com.google.inputmethod.Japanese";
                "Input Mode" = "com.apple.inputmethod.Roman";
                InputSourceKind = "Input Mode";
              }
              {
                "Bundle ID" = "com.google.inputmethod.Japanese";
                "Input Mode" = "com.apple.inputmethod.Japanese";
                InputSourceKind = "Input Mode";
              }
            ];
          };
        };
      }
      # FIXME: The following script is automatically registered as
      # application.com.google.inputmethod.Japanese.146947176.146947248
      (lib.mkIf false {
        launchd.agents.google-japanese-input = {
          serviceConfig = {
            ProgramArguments = [
              "${cfg.package}/Library/Input\ Methods/GoogleJapaneseInput.app/Contents/MacOS/GoogleJapaneseInput"
            ];
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
