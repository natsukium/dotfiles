{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.nix;
in
{
  options.programs.nix.target = {
    system = mkEnableOption "";
    user = mkEnableOption "";
    otherDistroUser = mkEnableOption "";
  };

  config = mkMerge [
    (mkIf (cfg.target.system or cfg.target.otherDistroUser) {
      nix = {
        settings = {
          # error: cannot link '/nix/store/.tmp-link' to '/nix/store/.links/...': File exists
          # https://github.com/NixOS/nix/issues/7273
          auto-optimise-store = pkgs.stdenv.isLinux;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://natsukium.cachix.org"
            "https://cache.natsukium.com/nixpkgs"
          ];
          trusted-public-keys = [
            "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="
            "nixpkgs:eWsaFvCVF6vABk5GUebfJ2I0qnBwn61e5hdOZfWAm1I="
          ];
          trusted-users = [
            "root"
            "@wheel"
          ] ++ optional pkgs.stdenv.isDarwin "@admin";
          sandbox = if pkgs.stdenv.isDarwin then "relaxed" else true;
          warn-dirty = false;
        };
        extraOptions = ''
          max-silent-time = 3600
        '';
      };
    })
    (mkIf (cfg.target.user or cfg.target.otherDistroUser) {
      nix.settings.use-xdg-base-directories = true;
    })
  ];
}
