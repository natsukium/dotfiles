# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
{
  flake.modules.nixos.libvirt =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixvirt = inputs.nixvirt.lib;
      cfg = config.my.virtualisation.libvirt;
    in
    {
      imports = [ inputs.nixvirt.nixosModules.default ];

      options.my.virtualisation.libvirt = {
        enable = lib.mkEnableOption "libvirt with a NAT network for local guests";

        dhcpHosts = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                mac = lib.mkOption {
                  type = lib.types.str;
                  description = "MAC address the guest's interface is given.";
                };

                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name the lease is registered under.";
                };

                ip = lib.mkOption {
                  type = lib.types.str;
                  description = "Address to hand out for that MAC.";
                };
              };
            }
          );
          default = [ ];
          description = ''
            Fixed leases on the guest network, contributed by the guests
            themselves.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.libvirt = {
          enable = true;
          # Windows 11 refuses to install without a TPM 2.0, and nothing else
          # here minds having one.
          swtpm.enable = true;

          connections."qemu:///system".networks = [
            {
              definition = nixvirt.network.writeXML (
                nixvirt.network.templates.bridge {
                  uuid = "4de77f71-1aba-49e0-a139-5454e752db84";
                  subnet_byte = 122;
                  dhcp_hosts = cfg.dhcpHosts;
                }
              );
              active = true;
            }
          ];
        };

        # Host shutdown stops a guest rather than saving it. A memory image
        # restored onto a disk that has since been replaced is a guest that never
        # comes back, and libvirt-guests starts a stopped guest again on the next
        # boot anyway.
        virtualisation.libvirtd.onShutdown = "shutdown";

        environment.systemPackages = [
          pkgs.virt-manager
          pkgs.virt-viewer
        ];

        users.users.${config.my.username}.extraGroups = [ "libvirtd" ];
      };
    };
}
