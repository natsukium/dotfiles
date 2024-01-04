{
  inputs,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (pkgs) lib stdenv;
  inherit (specialArgs) username;
in {
  imports = [
    # nixosModule, but it should be also available on nix-darwin
    inputs.nur.nixosModules.nur
    ../common.nix
  ];

  users.users.${username}.home = "/Users/${username}";

  security.pam.enableSudoTouchIdAuth = true;

  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;

  system.activationScripts.extraActivation.text = lib.optionalString stdenv.isAarch64 ''
    softwareupdate --install-rosetta --agree-to-license
  '';
}
