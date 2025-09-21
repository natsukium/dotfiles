{
  inputs,
  self,
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (inputs)
    brew-nix
    emacs-overlay
    firefox-addons
    nur-packages
    ;
  inherit (specialArgs) username;
in
{
  imports = [
    ../applications/nix/buildMachines.nix
    ./shared/comin
  ];

  nixpkgs.overlays = [
    brew-nix.overlays.default
    emacs-overlay.overlays.default
    firefox-addons.overlays.default
    nur-packages.overlays.default
  ]
  ++ lib.attrValues self.overlays;

  nixpkgs.config.allowUnfree = true;

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
  users.users.${username}.shell = pkgs.fish;

  # system.activationScripts only runs specific hardcoded activation scripts on nix-darwin
  # https://github.com/LnL7/nix-darwin/issues/663
  system.activationScripts.extraActivation.text = ''
    # shellcheck disable=SC2046
    ${lib.getExe pkgs.nix} store diff-closures $(find /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}
