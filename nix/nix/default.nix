{pkgs, ...}: {
  nix = {
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      cores = 4;
      experimental-features = ["nix-command" "flakes"];
      max-jobs = 2;
      sandbox = true;
      substituters = ["https://cache.nixos.org" "https://natsukium.cachix.org"];
      trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="];
      trusted-users = ["root" "@wheel"];
    };
  };
  nixpkgs.config = {allowUnfree = true;};
}
