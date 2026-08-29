{ lib, ... }:
import ../../lib/mkProfile.nix { inherit lib; } {
  name = "base";

  system = {
    my.services.comin.enable = lib.mkDefault true;
    my.nix.enable = lib.mkDefault true;
    my.nix.distributedBuilds.enable = lib.mkDefault true;
    my.nixpkgs.enable = lib.mkDefault true;
  };

  nixos = {
    my.services.tailscale.enable = lib.mkDefault true;
  };

  darwin = {
    my.programs.bash.enable = lib.mkDefault true;
  };

  home = {
    my.programs.fish.enable = lib.mkDefault true;
    my.programs.bash.enable = lib.mkDefault true;
    my.programs.nushell.enable = lib.mkDefault true;
    my.programs.readline.enable = lib.mkDefault true;
    my.programs.ssh.enable = lib.mkDefault true;
    my.programs.starship = {
      enable = lib.mkDefault true;
      enableFishAsyncPrompt = lib.mkDefault true;
    };
    my.nix.enable = lib.mkDefault true;
  };
}
