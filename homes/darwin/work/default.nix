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

    my.virtualisation.colima = {
      settings.disk = 200;
      enableKubernetes = true;
    };
  };
}
