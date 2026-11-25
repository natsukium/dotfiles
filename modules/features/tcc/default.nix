# TCC grants cannot be declared: macOS only accepts them from a person in System
# Settings. Modules that need one say so here, and `dotcli doctor` reports the
# grants that are missing or were recorded against an older code signature.
{ ... }:
{
  flake.modules.homeManager.tcc =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.tcc.grants;
    in
    {
      options.my.tcc.grants = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              executable = lib.mkOption {
                type = lib.types.str;
                description = "Executable inside the app bundle the grant belongs to.";
              };
              services = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.enum [
                    "Accessibility"
                    "FullDiskAccess"
                    "InputMonitoring"
                    "Microphone"
                    "ScreenRecording"
                  ]
                );
                description = "Privacy & Security permissions the bundle needs.";
              };
            };
          }
        );
        default = { };
        description = "TCC permissions each app bundle needs, keyed by bundle identifier.";
      };

      config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg != { }) {
        my.programs.dotcli.plugins.tcc = {
          source = ./dotcli;
          settings = {
            databases = [
              "${config.home.homeDirectory}/Library/Application Support/com.apple.TCC/TCC.db"
              "/Library/Application Support/com.apple.TCC/TCC.db"
            ];
            grants = cfg;
            codesign = "/usr/bin/codesign";
            csreq = "/usr/bin/csreq";
          };
        };
      };
    };
}
