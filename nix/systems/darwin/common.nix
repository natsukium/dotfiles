{specialArgs, ...}: let
  inherit (specialArgs) username;
in {
  imports = [../common.nix];

  users.users.${username}.home = "/Users/${username}";

  security.pam.enableSudoTouchIdAuth = true;

  services.nix-daemon.enable = true;

  programs.gnupg.agent.enable = true;

  nixpkgs.config.allowUnfree = true;
}
