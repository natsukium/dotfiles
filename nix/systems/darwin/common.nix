{specialArgs, ...}: let
  inherit (specialArgs) username;
in {
  imports = [../common.nix];

  users.users.${username}.home = "/Users/${username}";

  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;
}
