{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs.inputs) nixbins;
  bins = import nixbins {inherit pkgs;};
in {
  home.packages =
    if pkgs.stdenv.isLinux
    then [pkgs.vivaldi]
    else [bins.vivaldi];

  xdg.configFile."vivaldi/mod.css".text = ''
    #header {
      display: none;
    }

    #titlebar {
      display: none;
    }
  '';
}
