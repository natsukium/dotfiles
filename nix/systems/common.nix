{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs.inputs) neovim-nightly-overlay;
in {
  imports = [
    ../modules/nix
  ];

  nixpkgs.overlays = [neovim-nightly-overlay.overlay];

  programs.nix.target.system = true;

  nix.gc =
    {
      automatic = true;
      options = "--delete-older-than 7d";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      dates = "weekly";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
    };
}
