# Build a profile's registry entries from one declaration.
#
# A profile is a named toggle (my.profiles.<name>.enable) that fans a bundle of
# feature defaults out across scopes. The system-scope entry additionally
# forwards its own enable into home-manager.sharedModules, so a host flips the
# profile once at system level and the home half follows -- the deliberate,
# single crossing point between the two scopes (see design.org). Encoding that
# crossing here, rather than re-deriving it per profile, keeps every profile on
# one shape: a change to the mechanism (priority, the forwarding, an added
# assertion) lands in one place instead of needing to be found and replicated in
# each file, where a missed copy would silently stop forwarding.
#
#   name    profile name; drives the option path and the profile-<name> keys
#   home    home-scope config applied when enabled; null means the profile has
#           no home half (and so no forwarding is emitted, since nothing would
#           declare the option in home scope)
#   system  config applied on both nixos and darwin when enabled
#   nixos   nixos-only extra config
#   darwin  darwin-only extra config
{ lib }:
{
  name,
  home ? null,
  system ? { },
  nixos ? { },
  darwin ? { },
}:
let
  option.options.my.profiles.${name}.enable = lib.mkEnableOption "${name} profile";

  mkSystem =
    extra:
    { config, ... }:
    option
    // {
      config = lib.mkIf config.my.profiles.${name}.enable (
        lib.mkMerge [
          (lib.mkIf (home != null) {
            home-manager.sharedModules = [ { my.profiles.${name}.enable = lib.mkDefault true; } ];
          })
          system
          extra
        ]
      );
    };

  homeModule =
    { config, ... }:
    option
    // {
      config = lib.mkIf config.my.profiles.${name}.enable home;
    };
in
{
  flake.modules = {
    nixos."profile-${name}" = mkSystem nixos;
    darwin."profile-${name}" = mkSystem darwin;
  }
  // lib.optionalAttrs (home != null) {
    homeManager."profile-${name}" = homeModule;
  };
}
