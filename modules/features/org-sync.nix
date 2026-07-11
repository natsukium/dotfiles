# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager."org-sync" =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.org-sync;
    in
    {
      options.my.services.org-sync = {
        enable = lib.mkEnableOption "syncing the org folder across the user's devices";

        devices = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.id = lib.mkOption {
                type = lib.types.str;
                description = "Syncthing device ID.";
              };
            }
          );
          default = { };
          description = "Peer devices that participate in the org folder.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.syncthing = {
          enable = true;
          guiAddress = "127.0.0.1:8385";
          overrideDevices = true;
          overrideFolders = true;
          settings = {
            options.listenAddresses = [
              "tcp://0.0.0.0:22001"
              "quic://0.0.0.0:22001"
            ];
            devices = cfg.devices;
            folders.org = {
              path = "${config.home.homeDirectory}/dropbox/org";
              devices = lib.attrNames cfg.devices;
            };
          };
        };
      };
    };
}
