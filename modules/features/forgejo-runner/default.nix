# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  wrapperOptions =
    { lib, ... }:
    {
      options.my.services.forgejo-runner = {
        enable = lib.mkEnableOption "Forgejo Actions runner";

        url = lib.mkOption {
          type = lib.types.str;
          default = "https://git.natsukium.com";
          description = "Forgejo instance the runner registers with.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to an environment file holding the registration token as
            `TOKEN=...`. The host supplies this — typically a secret-manager path —
            so the feature stays free of any secret-store assumption.
          '';
        };

        labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Labels the runner advertises; each platform sets a default.";
        };
      };
    };

  mkInstance = config: hostPackages: {
    enable = true;
    name = config.networking.hostName;
    url = config.my.services.forgejo-runner.url;
    tokenFile = config.my.services.forgejo-runner.tokenFile;
    labels = config.my.services.forgejo-runner.labels;
    inherit hostPackages;
  };

  darwinWrapper =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    {
      imports = [
        ./darwin-module.nix
        wrapperOptions
      ];

      config = lib.mkIf config.my.services.forgejo-runner.enable {
        my.services.forgejo-runner.labels = lib.mkDefault [
          "aarch64-darwin:host"
        ];

        services.forgejo-runner.instances.default = mkInstance config (
          with pkgs;
          [
            bash
            curl
            git
            nix
            nodejs
            toybox
            inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.niks3
          ]
        );
      };
    };

  nixosWrapper =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.services.forgejo-runner;
    in
    {
      imports = [ wrapperOptions ];

      options.my.services.forgejo-runner = {
        uuid = lib.mkOption {
          type = lib.types.str;
          description = "UUID of the runner as registered with Forgejo.";
        };

        runnerTokenFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to a file holding only the runner token paired with {option}`uuid`.";
        };
      };

      config = lib.mkIf cfg.enable {
        my.services.forgejo-runner.labels = lib.mkDefault [
          "ubuntu-latest:docker://node:22-bookworm"
          "x86_64-linux:host"
        ];

        services.forgejo-runner = {
          package = pkgs.forgejo-runner;
          instances.default = {
            enable = true;
            settings = {
              runner.labels = cfg.labels;
              host.workdir_parent = "/var/lib/private/forgejo-runner/default/.cache/act";
              server.connections.default = {
                inherit (cfg) url uuid;
              };
            };
            secrets.server.connections.default.token_url = cfg.runnerTokenFile;
            hostPackages = with pkgs; [
              bash
              (lib.hiPrio gnutar)
              coreutils
              busybox
              curl
              git
              nix
              nodejs
              inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.niks3
            ];
          };
        };

        virtualisation.docker.enable = true;
      };
    };
in
{
  imports = [ ./windows ];

  flake.modules.darwin.forgejo-runner = darwinWrapper;
  flake.modules.nixos.forgejo-runner = nixosWrapper;
}
