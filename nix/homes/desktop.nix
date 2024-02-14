{ pkgs, config, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  imports = [
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../vscode
  ];

  services.copyq = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then nurpkgs.copyq else pkgs.copyq;
  };
}
