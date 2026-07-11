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
          "macos:host"
          "macos-aarch64:host"
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
    {
      imports = [ wrapperOptions ];

      config = lib.mkIf config.my.services.forgejo-runner.enable {
        my.services.forgejo-runner.labels = lib.mkDefault [
          "ubuntu-latest:docker://node:22-bookworm"
          "nix:host"
        ];

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.default = mkInstance config (
            with pkgs;
            [
              bash
              busybox
              curl
              git
              nix
              nodejs
              inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.niks3
            ]
          );
        };

        virtualisation.docker.enable = true;
      };
    };
in
{
  flake.modules.darwin.forgejo-runner = darwinWrapper;
  flake.modules.nixos.forgejo-runner = nixosWrapper;
}
