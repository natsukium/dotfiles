{
  lib,
  pkgs,
  config,
  ...
}:
let
  emacs-unwrapped = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.emacs-plus else pkgs.emacs-pgtk;

  tangle =
    org:
    let
      stem = path: lib.head (lib.splitString "." path);
      outName = "${stem (builtins.baseNameOf org)}.el";
    in
    pkgs.runCommandNoCC "${outName}" { nativeBuildInputs = [ emacs-unwrapped ]; } ''
      cp ${org} tmp.org
      emacs -Q --batch --eval \
        "(progn 
          (require 'ob-tangle)
          (org-babel-tangle-file \"tmp.org\" \"emacs-lisp\"))"
      install emacs-lisp $out
    '';

  emacs = pkgs.emacsWithPackagesFromUsePackage {
    package = emacs-unwrapped;
    config = ./init.org;
    alwaysTangle = true;
    extraEmacsPackages = epkgs: with epkgs; [ ];
  };
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };

  xdg.configFile."emacs/init.el".source = tangle ./init.org;
  xdg.configFile."emacs/early-init.el".source = tangle ./early-init.org;

  home.shellAliases = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    emacs = "${config.programs.emacs.package}/Applications/Emacs.app/Contents/MacOS/Emacs";
  };
}
