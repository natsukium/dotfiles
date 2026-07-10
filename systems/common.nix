{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (inputs)
    brew-nix
    edgepkgs
    firefox-addons
    nur-packages
    ;
in
{
  imports = [
    ../modules/shared/nix/build-machines.nix
    ./shared/comin
  ];

  nixpkgs.overlays = [
    brew-nix.overlays.default
    edgepkgs.overlays.default
    firefox-addons.overlays.default
    nur-packages.overlays.default
  ]
  ++ lib.attrValues inputs.self.overlays;

  # system.activationScripts only runs specific hardcoded activation scripts on nix-darwin
  # https://github.com/LnL7/nix-darwin/issues/663
  system.activationScripts.extraActivation.text = ''
    profiles=$(find /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -2)
    profile_count=$(echo "$profiles" | wc -l)
    if [ "$profile_count" -ge 2 ]; then
      # shellcheck disable=SC2086
      ${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' store diff-closures $profiles
    else
      echo "No previous generation to compare with."
    fi
  '';
}
