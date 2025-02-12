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
        system.activationScripts.extraActivation.text = ''
          echo "copying google-japanese-input into /Library..."
          cp -r ${cfg.package}/Library/Input\ Methods /Library/
        '';

        environment.userLaunchAgents = {
          "com.google.inputmethod.Japanese.Converter.plist".source =
            "${cfg.package}/Library/LaunchAgents/com.google.inputmethod.Japanese.Converter.plist";
          "com.google.inputmethod.Japanese.Renderer.plist".source =
            "${cfg.package}/Library/LaunchAgents/com.google.inputmethod.Japanese.Renderer.plist";
        };
      }
      # FIXME: The following script is automatically registered
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
