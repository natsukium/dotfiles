{ pkgs, config, ... }:
let
  emacs = pkgs.emacsWithPackagesFromUsePackage {
    package = if pkgs.stdenv.isDarwin then pkgs.emacs30-plus else pkgs.emacs30-pgtk;
    config = ./init.el;
    extraEmacsPackages = epkgs: with epkgs; [ ];
  };
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };

  xdg.configFile."emacs/init.el".source = ./init.el;

  home.shellAliases = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    emacs = "${config.programs.emacs.package}/Applications/Emacs.app/Contents/MacOS/Emacs";
  };
}
