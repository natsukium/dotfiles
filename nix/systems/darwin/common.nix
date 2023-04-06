{specialArgs, ...}: let
  inherit (specialArgs) username;
in {
  users.users.${username}.home = "/Users/${username}";

  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://natsukium.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="
    ];
    trusted-users = ["root" "@wheel"];
  };
}
