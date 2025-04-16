{
  inputs,
  self,
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (inputs) emacs-overlay firefox-addons nur-packages;
  inherit (specialArgs) username;
in
{
  imports = [
    ../modules/nix
    ../applications/nix/buildMachines.nix
  ];

  nixpkgs.overlays = [
    emacs-overlay.overlays.default
    firefox-addons.overlays.default
    nur-packages.overlays.default
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
    };

  nix.optimise.automatic = true;

  nix.channel.enable = false;

  # system.activationScripts only runs specific hardcoded activation scripts on nix-darwin
  # https://github.com/LnL7/nix-darwin/issues/663
  system.activationScripts.extraActivation.text = ''
    # shellcheck disable=SC2046
    ${lib.getExe pkgs.nix} store diff-closures $(find /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}
