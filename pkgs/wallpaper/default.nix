{
  wallpaper,
  palette,
  width ? 3440,
  height ? 1440,
  logoSize ? 90,
  logoRotate ? "-10",
  logoGravity ? "east",
  logoOffset ? "+500+0",
  ...
}:
wallpaper.override {
  inherit
    width
    height
    logoSize
    logoRotate
    logoGravity
    logoOffset
    ;

  backgroundColor = "#${palette.base00}";
  logoColors = with palette; rec {
    color0 = "#${base0C}";
    color1 = "#${base0D}";
    color2 = color0;
    color3 = color1;
    color4 = color0;
    color5 = color1;
  };
}
