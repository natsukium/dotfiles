{ specialArgs, pkgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../desktop.nix
      ./accounts.nix
      ./git.nix
    ];

    home.packages = with pkgs; [
      brewCasks.slack
      google-chrome
      google-cloud-sdk
    ];

    services.ollama.enable = true;
  };
}
