{ specialArgs, pkgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/base.nix
      ../../../modules/profiles/home/development.nix
      ../desktop.nix
      ./accounts.nix
      ./git.nix
    ];

    home.packages = with pkgs; [
      brewCasks.meetingbar
      brewCasks.slack
      google-chrome
      google-cloud-sdk
    ];

    services.ollama.enable = true;

    my.programs.just.enableEnhancedCompletion = true;

    my.virtualisation.colima = {
      settings.disk = 200;
      enableKubernetes = true;
    };
  };
}
