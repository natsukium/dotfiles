{ pkgs, ... }:
{
  imports = [
    ../../applications/hyprland
    ../desktop.nix
  ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc ];
  };

  home.packages = [ pkgs.wofi ];

  services.mako = {
    enable = true;
    font = "HackGen35 Console 12";
    width = 300;
    height = 100;
    borderRadius = 5;
    borderSize = 2;
    defaultTimeout = 15000;
    extraConfig = ''
      [mode=do-not-disturb]
      invisible=1
    '';
  };
}
