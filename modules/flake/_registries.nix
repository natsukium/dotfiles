{ lib, ... }:
{
  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
  };
}
