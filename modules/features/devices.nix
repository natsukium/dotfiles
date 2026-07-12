# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  # Internal registry: hosts enable my.devices.*.
  flake.modules.nixos.devices =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.devices;
    in
    {
      options.my.devices.audio.at2040.enable =
        lib.mkEnableOption "AT2040 USB mic sink demotion so it does not steal the default output";

      config = lib.mkIf cfg.audio.at2040.enable {
        services.pipewire.wireplumber.extraConfig."51-at2040-demote-sink" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "media.class" = "Audio/Sink";
                  "alsa.card_name" = "AT2040USB";
                }
              ];
              actions.update-props = {
                "priority.driver" = 0;
                "priority.session" = 0;
              };
            }
          ];
        };
      };
    };
}
