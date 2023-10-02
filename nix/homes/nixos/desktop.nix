{pkgs, ...}: {
  imports = [
    ../../applications/hyprland
    ../desktop.nix
  ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
  };

  home.packages = [
    pkgs.wofi
  ];
}
