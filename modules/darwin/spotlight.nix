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
      # Target every volume with `-a` rather than just `/`. On modern macOS the
      # boot disk is split into a read-only System volume (`/`) and a writable
      # Data volume (`/System/Volumes/Data`), and `/Users`, `/Applications` and
      # `/Library` are firmlinks into Data. Indexing on `/` is already disabled
      # because it is read-only, so `mdutil -i off /` looks like it works while
      # the Data volume keeps indexing and `mdworker` keeps churning the disk.
      mdutil -i off -d -a &> /dev/null
      # Erase the now-orphaned index stores to reclaim disk (Data is near full).
      mdutil -E -a &> /dev/null
    '';
  };
}
