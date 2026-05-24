# Requires: inputs.emacs-overlay
{ lib, inputs, ... }:
let
  withEmacsOverlay = pkgs: pkgs.extend inputs.emacs-overlay.overlays.default;

  mkEmacs = pkgs: (withEmacsOverlay pkgs).callPackage ./package.nix { };

  tangle =
    pkgs: org:
    let
      epkgs = withEmacsOverlay pkgs;
      emacs-unwrapped = if pkgs.stdenv.hostPlatform.isDarwin then epkgs.emacs-plus else epkgs.emacs-pgtk;
      stem = name: lib.head (lib.splitString "." name);
      outName = "${stem (baseNameOf (toString org))}.el";
    in
    pkgs.runCommand outName { nativeBuildInputs = [ emacs-unwrapped ]; } ''
      cp ${org} tmp.org
      emacs -Q --batch --eval \
        "(progn
          (require 'ob-tangle)
          (org-babel-tangle-file \"tmp.org\" \"emacs-lisp\"))"
      install emacs-lisp $out
    '';
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

        xdg.configFile."emacs/init.el".source = tangle pkgs ./init.org;
        xdg.configFile."emacs/early-init.el".source = tangle pkgs ./early-init.org;
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
