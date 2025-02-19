{ lib, ... }:
{
  options = {
    system.defaults.inputsources.AppleEnabledThirdPartyInputSources = lib.mkOption {
      type = lib.types.nullOr lib.types.listOf lib.types.attrs;
      default = null;
      description = lib.mdDoc ''
        Additional third-party input source which enabled for input methods.
      '';
      example = ''
        [
          {
            "Bundle ID" = "com.google.inputmethod.Japanese";
            InputSourceKind = "Keyboard Input Method";
          }
          {
            "Bundle ID" = "com.google.inputmethod.Japanese";
            "Input Mode" = "com.apple.inputmethod.Japanese";
            InputSourceKind = "Input Mode";
          }
        ]
      '';
    };
  };
}
