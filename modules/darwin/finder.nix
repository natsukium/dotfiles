{ config, lib, ... }:

with lib;

{
  options = {
    system.defaults.finder.FXRemoveOldTrashItems = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to remove trash items after a month. The default is false.
      '';
    };
  };
}
