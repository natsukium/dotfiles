{
  inputs,
  self,
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (inputs) emacs-overlay nur-packages;
  inherit (specialArgs) username;
in
{
  imports = [
    ../modules/nix
    ../applications/nix/buildMachines.nix
  ];

  nixpkgs.overlays = [
    nur-packages.overlays.default
    emacs-overlay.overlays.default
  ] ++ lib.attrValues self.overlays;

  programs.nix.target.system = true;

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
  users.users.${username}.shell = pkgs.fish;

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

      # cachix deploy fails
      # error: A single-user install can't run gc as root, aborting activation
      user = "root";
    };

  nix.optimise =
    {
      automatic = true;
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # cachix deploy fails
      # error: A single-user install can't run optimiser as root, aborting activation
      user = "root";
    };

  nix.channel.enable = false;

  # system.activationScripts only runs specific hardcoded activation scripts on nix-darwin
  # https://github.com/LnL7/nix-darwin/issues/663
  system.activationScripts.extraActivation.text = ''
    ${lib.getExe pkgs.nix} store diff-closures "$(find /nix/var/nix/profiles/system-*-link/ | tail -2)"
  '';
}
