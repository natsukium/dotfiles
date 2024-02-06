{ lib, config, ... }:
let
  cfg = config.programs.chromium;
in
with lib;
{
  options.programs.chromium = {
    enableOzone = mkOption {
      type = types.bool;
      default = config.wayland.windowManager.hyprland.enable;
      description = "Enable Ozone support";
    };
  };

  config = mkIf cfg.enable (
    (mkIf cfg.enableOzone {
      home.sessionVariables = {
        NIXOS_OZONE_WL = 1;
      };
    })
  );
}
