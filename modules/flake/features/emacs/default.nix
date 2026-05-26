# Requires: inputs.emacs-overlay
{ lib, inputs, ... }:
let
  withEmacsOverlay = pkgs: pkgs.extend inputs.emacs-overlay.overlays.default;

  emacsUnwrapped =
    pkgs:
    let
      epkgs = withEmacsOverlay pkgs;
    in
    if pkgs.stdenv.hostPlatform.isDarwin then epkgs.emacs-plus else epkgs.emacs-pgtk;

  # Pass target-file to org-babel-tangle-file so blocks without an explicit
  # :tangle header still get tangled; emacs-overlay's defaultInitFile path
  # calls plain org-babel-tangle, which would tangle 0 blocks here.
  tangle =
    pkgs:
    {
      name,
      org,
    }:
    pkgs.runCommand name { nativeBuildInputs = [ (emacsUnwrapped pkgs) ]; } ''
      cp ${org} tmp.org
      emacs -Q --batch --eval \
        "(progn
          (require 'ob-tangle)
          (org-babel-tangle-file \"tmp.org\" \"emacs-lisp\"))"
      install emacs-lisp $out
    '';

  tangleEl =
    pkgs: org:
    let
      stem = name: lib.head (lib.splitString "." name);
    in
    tangle pkgs {
      name = "${stem (baseNameOf (toString org))}.el";
      inherit org;
    };

  mkEmacs =
    pkgs:
    (withEmacsOverlay pkgs).callPackage ./package.nix {
      defaultInitFile = tangle pkgs {
        name = "default.el";
        org = ./init.org;
      };
    };
in
{
  flake.homeManagerModules.emacs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.emacs.enable = lib.mkEnableOption "emacs";

      config = lib.mkIf config.my.programs.emacs.enable {
        programs.emacs = {
          enable = true;
          package = mkEmacs pkgs;
        };

        services.emacs = {
          enable = true;
          client.enable = true;
        };

        xdg.configFile."emacs/init.el".source = tangleEl pkgs ./init.org;
        xdg.configFile."emacs/early-init.el".source = tangleEl pkgs ./early-init.org;
        home.file.".authinfo.age".source = ./authinfo.age;

        home.shellAliases = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          emacs = "${config.programs.emacs.package}/Applications/Emacs.app/Contents/MacOS/Emacs";
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.emacs = mkEmacs pkgs;
    };
}
