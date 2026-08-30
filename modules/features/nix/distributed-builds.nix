# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  systemModule =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.nix.distributedBuilds;
      inherit (inputs.self.outputs.nixosConfigurations) kilimanjaro serengeti tarangire;
      inherit (inputs.self.outputs.darwinConfigurations) mikumi;
    in
    {
      options.my.nix.distributedBuilds = {
        enable = lib.mkEnableOption "distributed builds";

        connectTimeout = lib.mkOption {
          type = lib.types.ints.positive;
          default = 5;
          description = "SSH ConnectTimeout in seconds for reaching build machines.";
        };

        machines = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                publicKey = lib.mkOption { type = lib.types.str; };
                systems = lib.mkOption { type = lib.types.listOf lib.types.str; };
                maxJobs = lib.mkOption { type = lib.types.ints.positive; };
                speedFactor = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 1;
                };
                supportedFeatures = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                excludeHosts = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
              };
            }
          );
          description = "Build machines the fleet can offload to.";
          default = {
            tarangire = {
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJJYgE/dmYLXYBrVnPicd0qsaUeqcBtXB8H9LHkJ2j4";
              systems = [
                "x86_64-linux"
                "i686-linux"
              ];
              maxJobs = tarangire.config.nix.settings.max-jobs;
              speedFactor = 5;
              supportedFeatures = tarangire.config.nix.settings.system-features;
            };
            kilimanjaro = {
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhpfAalh6A5xDSE+HOdNE29ZgIjlP7tdlhHs82boSwp";
              systems = [
                "x86_64-linux"
                "i686-linux"
              ];
              maxJobs = kilimanjaro.config.nix.settings.max-jobs;
              supportedFeatures = kilimanjaro.config.nix.settings.system-features;
            };
            serengeti = {
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWwhfhDSZ+M2XDwP2MlC/zFfVpk3WjUxV/JWFgGzgNW";
              systems = [ "aarch64-linux" ];
              maxJobs = serengeti.config.nix.settings.max-jobs;
              supportedFeatures = serengeti.config.nix.settings.system-features;
            };
            mikumi = {
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfWOWKBFuDV08g6xP9MMY78CERI02CNG+5dy8CXQmXs";
              systems = [
                "aarch64-darwin"
                "x86_64-darwin"
              ];
              maxJobs = mikumi.config.nix.settings.max-jobs;
              supportedFeatures = [
                "apple-virt"
                "benchmark"
                "big-parallel"
                "nixos-test"
              ];
              excludeHosts = [ "work" ];
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        nix = {
          distributedBuilds = true;

          extraOptions = ''
            builders-use-substitutes = true
          '';

          buildMachines = lib.pipe cfg.machines [
            (lib.filterAttrs (
              name: machine:
              name != config.networking.hostName && !(lib.elem config.networking.hostName machine.excludeHosts)
            ))
            (lib.mapAttrsToList (
              hostName: machine: {
                inherit hostName;
                protocol = "ssh-ng";
                inherit (machine)
                  systems
                  maxJobs
                  speedFactor
                  supportedFeatures
                  ;
                sshUser = "natsukium";
                mandatoryFeatures = [ ];
              }
            ))
          ];
        };

        programs.ssh.knownHosts = lib.mapAttrs (_: machine: { inherit (machine) publicKey; }) cfg.machines;

        programs.ssh.extraConfig = ''
          Host ${lib.concatStringsSep " " (lib.attrNames cfg.machines)}
            ConnectTimeout ${toString cfg.connectTimeout}
        '';
      };
    };
in
{
  flake.modules.nixos.distributed-builds = systemModule;
  flake.modules.darwin.distributed-builds = systemModule;
}
