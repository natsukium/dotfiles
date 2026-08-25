# Requires: inputs.emacs-overlay
{ lib, inputs, ... }:
let
  withEmacsOverlay = pkgs: pkgs.extend inputs.emacs-overlay.overlays.default;

  emacsUnwrapped =
    pkgs:
    let
      epkgs = withEmacsOverlay pkgs;
    in
    if pkgs.stdenv.hostPlatform.isDarwin then epkgs.emacs31-plus else epkgs.emacs31-pgtk;

  # Pass target-file to org-babel-tangle-file so blocks without an explicit
  # :tangle header still get tangled; plain org-babel-tangle would tangle
  # 0 blocks here.
  #
  # Tangling writes no file header, so the lexical-binding cookie is prepended
  # here; without it Emacs loads the config under dynamic binding.
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
      {
        echo ";;; -*- lexical-binding: t; -*-"
        cat emacs-lisp
      } > $out
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
      org-clickup-src = inputs.org-clickup;
    };

  # `nix run .#emacs` should start this config even for someone who has their
  # own init files. Bundling the config as default.el cannot deliver that:
  # default.el loads after the user's init, so a guest gets both configs mixed,
  # and with the home-manager-managed init.el the whole config was evaluated
  # twice per startup. A writable --init-directory sidesteps both: the guest's
  # ~/.config/emacs is never read, and state (elpa, eln-cache, savehist) lands
  # outside the read-only store.
  mkStandalone =
    pkgs:
    let
      emacs = mkEmacs pkgs;
      emacsBin =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${emacs}/Applications/Emacs.app/Contents/MacOS/Emacs"
        else
          "${emacs}/bin/emacs";
    in
    pkgs.writeShellScriptBin "emacs" ''
      dir="''${XDG_CACHE_HOME:-$HOME/.cache}/natsukium-emacs"
      mkdir -p "$dir"
      ln -sf ${tangleEl pkgs ./init.org} "$dir/init.el"
      ln -sf ${tangleEl pkgs ./early-init.org} "$dir/early-init.el"
      exec ${emacsBin} --init-directory "$dir" "$@"
    '';
in
{
  flake.modules.homeManager.emacs =
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

        launchd.agents = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          emacs.config.EnvironmentVariables.PATH = lib.concatStringsSep ":" [
            "${config.home.profileDirectory}/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
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
      packages.emacs = mkStandalone pkgs;
    };
}
