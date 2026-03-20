{ specialArgs, pkgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/base.nix
      ../../../modules/profiles/home/desktop.nix
      ../../../modules/profiles/home/development.nix
      ../desktop.nix
      ./accounts.nix
      ./git.nix
    ];

    home.packages = with pkgs; [
      brewCasks.slack
      google-chrome
      google-cloud-sdk
      meetingbar
    ];

    my.programs.just.enableEnhancedCompletion = true;

    services.colima.profiles.default = {
      # Docker Desktop is installed on the work machine
      isActive = false;
      settings = {
        disk = 200;
        kubernetes.enabled = true;
      };
    };
  };
}
