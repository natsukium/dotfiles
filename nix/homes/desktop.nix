{pkgs, ...}: {
  imports = [
    ../applications/hyprland
    ../applications/kitty
    ../applications/qutebrowser
    ../applications/vivaldi
    ../vscode
  ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
  };

  home.packages =
    [
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
      pkgs.wofi
    ];
}
