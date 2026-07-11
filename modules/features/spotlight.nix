# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.darwin.spotlight =
    { config, lib, ... }:
    let
      cfg = config.my.services.spotlight;
    in
    {
      options.my.services.spotlight = {
        enableIndex = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether Spotlight indexes the volumes on this machine.";
        };
      };

      config = {
        system.activationScripts.extraActivation.text =
          if cfg.enableIndex then
            ''
              echo "enabling spotlight indexing..."
              mdutil -i on -a &> /dev/null
            ''
          else
            ''
              echo "disabling spotlight indexing..."
              mdutil -i off -d -a &> /dev/null
              mdutil -E -a &> /dev/null
            '';
      };
    };
}
