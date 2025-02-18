{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (inputs) nixpkgs;
in
{
  system.stateVersion = "23.11";

  terminal.font = "${pkgs.hackgen-nf-font}/share/fonts/hackgen-nf/HackGenConsoleNF-Regular.ttf";

  environment.packages = with pkgs; [
    openssh
    which
  ];

  time.timeZone = "Asia/Tokyo";

  nix = {
    registry.nixpkgs.flake = nixpkgs;
    substituters = [ "https://natsukium.cachix.org" ];
    trustedPublicKeys = [ "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI=" ];
    extraOptions = ''
      experimental-features = nix-command flakes
      sandbox = true
      warn-dirty = false
    '';
  };

  user = {
    shell = "${lib.getExe pkgs.fish}";
  };
}
