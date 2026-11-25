# `dotcli`: the per-machine setup Nix cannot do declaratively — a private key to
# create, an OAuth consent screen to click through.
#
# Each step is a plugin owned by the module whose configuration it completes, so
# the Python sits beside the Nix that knows the paths and service names, and a
# host only gets the subcommands for features it enables. A single script would
# have to hard-code those paths and drift whenever a module changed them.
{ ... }:
{
  flake.modules.homeManager.dotcli =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.dotcli;
    in
    {
      options.my.programs.dotcli = {
        plugins = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                source = lib.mkOption {
                  type = lib.types.path;
                  description = ''
                    Python package directory whose __init__.py provides HELP,
                    register(parser, settings) and doctor(settings). Its test_*.py
                    files run with pytest when the package is built and are not installed.
                  '';
                };
                settings = lib.mkOption {
                  inherit (pkgs.formats.json { }) type;
                  default = { };
                  description = "Values passed to the plugin's register() and doctor().";
                };
              };
            }
          );
          default = { };
          description = "`dotcli <name> <action>` command groups, keyed by name.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = pkgs.callPackage ./package.nix { inherit (cfg) plugins; };
        };
      };

      config = lib.mkIf (cfg.plugins != { }) {
        assertions = lib.concatMap (name: [
          {
            assertion = builtins.match "[a-z_][a-z0-9_]*" name != null;
            message = "my.programs.dotcli.plugins.${name}: the name becomes a Python module name";
          }
          {
            assertion = name != "doctor";
            message = "my.programs.dotcli.plugins.doctor: the name is taken by `dotcli doctor`";
          }
        ]) (lib.attrNames cfg.plugins);

        home.packages = [ cfg.package ];
      };
    };
}
