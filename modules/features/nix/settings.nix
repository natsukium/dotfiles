# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  systemModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.nix;
    in
    {
      options.my.nix = {
        enable = lib.mkEnableOption "Nix configuration";

        enableFlakes = lib.mkOption {
          default = true;
          example = false;
          description = "Whether to enable flakes.";
          type = lib.types.bool;
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          (lib.mkIf cfg.enableFlakes {
            nix = {
              settings.experimental-features = [
                "flakes"
                "nix-command"
              ];
              channel.enable = false;
            };
          })
          {
            nix.optimise.automatic = true;
            nix.settings.auto-optimise-store = true;

            nix.settings.warn-dirty = false;

            nix.settings = {
              substituters = [
                "https://nix-cache.natsukium.com"
                "https://natsukium.cachix.org"
                "https://cache.nixos-cuda.org"
              ];

              trusted-public-keys = [
                "niks3-1:SoIFTPtiPoCW3/OzUkIBKlLG5znMZfbihlr11XAOles="
                "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="
                "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
              ];
            };

            nix.settings.sandbox = if pkgs.stdenv.hostPlatform.isDarwin then "relaxed" else true;

            nix.settings.trusted-users = [
              "root"
              "@wheel"
            ]
            ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "@admin";

            nix.gc = {
              automatic = true;
              options = "--delete-older-than 7d";
            };

            nix.extraOptions = ''
              max-silent-time = 3600
            '';
          }
        ]
      );
    };
in
{
  flake.modules.nixos.nix = systemModule;
  flake.modules.darwin.nix = systemModule;

  flake.modules.homeManager.nix =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.nix;
    in
    {
      options.my.nix.enable = lib.mkEnableOption "nix";

      config = lib.mkIf cfg.enable {
        nix.settings.use-xdg-base-directories = config.xdg.enable;

        programs.git.ignores = [ "result" ];
      };
    };
}
