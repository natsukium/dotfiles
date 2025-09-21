{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.nix;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    types
    ;
in
{
  options.my.nix = {
    enable = mkEnableOption "Nix configuration";

    enableFlakes = mkOption {
      default = true;
      example = false;
      description = "Whether to enable flakes.";
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.enableFlakes {
      nix = {
        settings.experimental-features = [
          "flakes"
          "nix-command"
        ];
        channel.enable = false;
      };
    })
    (mkIf (config.nix ? optimise) {
      nix.optimise.automatic = true;
    })
    {
      nix = {
        settings = {
          warn-dirty = false;

          substituters = [
            "https://natsukium.cachix.org"
            "https://nix-community.cachix.org"
          ];

          trusted-public-keys = [
            "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];

          # error: cannot link '/nix/store/.tmp-link' to '/nix/store/.links/...': File exists
          # https://github.com/NixOS/nix/issues/7273
          auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;

          sandbox = if pkgs.stdenv.hostPlatform.isDarwin then "relaxed" else true;

          trusted-users = [
            "root"
            "@wheel"
          ]
          ++ optional pkgs.stdenv.isDarwin "@admin";
        };

        gc = {
          automatic = true;
          options = "--delete-older-than 7d";
        };

        extraOptions = ''
          max-silent-time = 3600
        '';
      };
    }
  ]);
}
