{ pkgs, specialArgs, ... }:
let
  inherit (pkgs) lib stdenv;
  inherit (specialArgs) username;
in
{
  imports = [
    ../common.nix
    ../../modules/darwin
  ];

  users.users.${username}.home = "/Users/${username}";

  services.tailscale.enable = true;

  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;

  # need to run `chsh -s /run/current-system/sw/bin/fish` manually
  # https://github.com/LnL7/nix-darwin/issues/811
  system.activationScripts.extraActivation.text =
    ''
      chsh -s /run/current-system/sw/bin/fish
    ''
    + lib.optionalString stdenv.isAarch64 ''
      softwareupdate --install-rosetta --agree-to-license
    '';

  system.stateVersion = 5;
}
