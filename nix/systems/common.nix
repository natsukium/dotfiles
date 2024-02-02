{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (inputs) neovim-nightly-overlay emacs-overlay;
in
{
  imports = [ ../modules/nix ];

  nixpkgs.overlays = [
    neovim-nightly-overlay.overlay
    emacs-overlay.overlays.default
  ];

  programs.nix.target.system = true;

  nix.gc =
    {
      automatic = true;
      options = "--delete-older-than 7d";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux { dates = "weekly"; }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
    };
}
