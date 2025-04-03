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
      google-chrome
    ];

    services.ollama.enable = true;
  };
}
