{
  pkgs,
  specialArgs,
  ...
}:
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

  system.activationScripts.extraActivation.text = lib.optionalString stdenv.isAarch64 ''
    softwareupdate --install-rosetta --agree-to-license
  '';
}
