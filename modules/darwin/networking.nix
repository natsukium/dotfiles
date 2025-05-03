{ config, lib, ... }:
let
  cfg = config.my.networking;

  netutils = import ../../lib/netutils.nix { inherit lib; };

  addressOptions = {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "The IP address of the interface.";
      };

      prefixLength = lib.mkOption {
        type = lib.types.addCheck lib.types.int (n: n >= 0 && n <= 32);
        description = "The prefix length of the interface address.";
      };
    };
  };

  interfaceOptions = {
    options = {
      ipv4 = {
        addresses = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule addressOptions);
          default = [ ];
          description = "List of IPv4 addresses of the interface.";
          example = lib.literalExpression ''
            [
              {
                address = "192.168.1.2";
                prefixLength = 24;
              }
            ]
          '';
        };
      };
    };
  };
in
{
  options = {
    my.networking = {
      interfaces = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule interfaceOptions);
        default = { };
        description = "The set of interface configurations.";
        example = lib.literalExpression ''
          {
            Ethernet = {
              ipv4.addresses = [
                {
                  address = "192.168.1.2";
                  prefixLength = 24;
                }
              ];
            };
            "Wi-Fi" = {
              ipv4.addresses = [
                {
                  address = "192.168.2.3";
                  prefixLength = 24;
                }
              ];
            };
          }
        '';
      };
    };
  };

  config = lib.mkIf (cfg.interfaces != { }) {
    system.activationScripts.networking.text =
      let
        configureAddress = name: address: ''
          echo "Configuring interface ${name} with ${address.address}/${toString address.prefixLength}"
          networksetup -setmanual "${name}" ${address.address} ${netutils.prefixLengthToSubnetMask address.prefixLength}
        '';

        configureInterface =
          name: interface: lib.concatMapStrings (addr: configureAddress name addr) interface.ipv4.addresses;
      in
      ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList configureInterface cfg.interfaces)}
      '';
  };
}
