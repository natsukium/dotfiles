{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.wallpaper;
  wallpaper = inputs.nix-wallpaper.packages.${pkgs.stdenv.hostPlatform.system}.wallpaper;
in
with lib;
{
  options.services.wallpaper = {
    enable = mkEnableOption "Enable the wallpaper service";
    imagePath = mkOption {
      type = types.path;
      default = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
      description = "Path to the image to use as wallpaper";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isLinux {
      home.packages = [ pkgs.swaybg ];
      wayland.windowManager.hyprland.extraConfig = ''
        exec-once = swaybg -i ${cfg.imagePath}
      '';
    })
    (mkIf pkgs.stdenv.isDarwin {
      home.activation.set-wallpaper = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        /usr/bin/osascript -e '
          set desktopImage to POSIX file "${cfg.imagePath}"
          tell application "Finder"
          set desktop picture to desktopImage
          end tell'
      '';
    })
  ]);
}
