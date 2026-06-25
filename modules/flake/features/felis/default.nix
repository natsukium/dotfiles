{ inputs, ... }:
let
  daemon =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
in
{
  flake.modules.nixos.felis = daemon;
  flake.modules.darwin.felis = daemon;

  flake.modules.homeManager.felis =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.colorScheme) palette;
      font-features = [
        "calt"
        "liga"
        "ss01"
        "ss02"
        "ss03"
        "ss05"
        "ss09"
      ];
    in
    {
      imports = [ inputs.felis.homeManagerModules.felis ];

      options.my.programs.felis.enable = lib.mkEnableOption "felis";

      config = lib.mkIf config.my.programs.felis.enable {
        programs.felis = {
          enable = true;
          package = inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;

          settings = {
            font = {
              family = "Moralerspace Neon HW";
              size = 14.0;
              features = font-features;
            };

            theme = {
              fg = "#${palette.base05}";
              bg = "#${palette.base00}";
              cursor = "#${palette.base05}";
              palette = {
                black = "#${palette.base00}";
                red = "#${palette.base08}";
                green = "#${palette.base0B}";
                yellow = "#${palette.base0A}";
                blue = "#${palette.base0D}";
                magenta = "#${palette.base0E}";
                cyan = "#${palette.base0C}";
                white = "#${palette.base05}";
                bright_black = "#${palette.base03}";
                bright_red = "#${palette.base08}";
                bright_green = "#${palette.base0B}";
                bright_yellow = "#${palette.base0A}";
                bright_blue = "#${palette.base0D}";
                bright_magenta = "#${palette.base0E}";
                bright_cyan = "#${palette.base0C}";
                bright_white = "#${palette.base07}";
              };
            };
            window = {
              decorations = false;
            };
          };
        };
      };
    };
}
