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
    pkgs.runCommand "${outName}" { nativeBuildInputs = [ emacs-unwrapped ]; } ''
      cp ${org} tmp.org
      emacs -Q --batch --eval \
        "(progn 
          (require 'ob-tangle)
          (org-babel-tangle-file \"tmp.org\" \"emacs-lisp\"))"
      install emacs-lisp $out
    '';

  claude-code-ide =
    epkgs:
    epkgs.melpaBuild {
      pname = "claude-code-ide";
      version = "0-unstable-2026-01-02";
      src = pkgs.fetchFromGitHub {
        owner = "manzaltu";
        repo = "claude-code-ide.el";
        rev = "760240d7f03ff16f90ede9d4f4243cd94f3fed73";
        hash = "sha256-Abs8+r5bQSkRJC74TEq1RRZtvj4TYmL1Vijq6KO9GG4=";
      };
      packageRequires = with epkgs; [
        transient
        vterm
        websocket
        web-server
      ];
    };

  emacs = pkgs.emacsWithPackagesFromUsePackage {
    package = emacs-unwrapped;
    config = ./init.org;
    alwaysTangle = true;
    extraEmacsPackages =
      epkgs: with epkgs; [
        treesit-grammars.with-all-grammars
        (claude-code-ide epkgs)
        pkgs.notmuch.emacs
        pkgs.age
        pkgs.gettext
      ];
  };
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };

  xdg.configFile."emacs/init.el".source = tangle ./init.org;
  xdg.configFile."emacs/early-init.el".source = tangle ./early-init.org;
  home.file.".authinfo.age".source = ./authinfo.age;

  home.shellAliases = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    emacs = "${config.programs.emacs.package}/Applications/Emacs.app/Contents/MacOS/Emacs";
  };
}
