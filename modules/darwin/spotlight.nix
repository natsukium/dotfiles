{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.spotlight;
in
{
  options = {
    my.services.spotlight = {
      enableIndex = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf (!cfg.enableIndex) {
    # TODO: enable indexing when `enableIndex = true`
    system.activationScripts.extraActivation.text = ''
      echo "disabling spotlight indexing..."
      mdutil -i off -d / &> /dev/null
      mdutil -E / &> /dev/null
    '';
  };
}
