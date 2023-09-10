{pkgs, lib, ...}: {
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      sandbox = true;
      use-xdg-base-directories = true;
    };
  };
  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
}
