{ ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = {
        fastfetch = pkgs.callPackage ../../../pkgs/fastfetch { };
        html =
          with pkgs;
          let
            org-html-themes = fetchurl {
              url = "https://raw.githubusercontent.com/fniessen/org-html-themes/b3898f4c5b09b3365fd93fd1566f46ecd0a8911f/org/theme-readtheorg.setup";
              hash = "sha256-+5gy+S6NcuvlV61fudbCNoCKmSrCdA9P5CHeGKlDrSM=";
            };
            org-to-html = ../../../scripts/org-to-html.el;
          in
          stdenvNoCC.mkDerivation {
            name = "dotfiles";
            src = lib.cleanSource ../../..;
            postPatch = ''
              substituteInPlace configuration.org \
                --replace-fail "https://fniessen.github.io/org-html-themes/org/theme-readtheorg.setup" "${org-html-themes}"
            '';
            nativeBuildInputs = [
              (emacs.pkgs.withPackages (epkgs: [
                epkgs.htmlize
                epkgs.nix-ts-mode
                (epkgs.treesit-grammars.with-grammars (g: [ g.tree-sitter-nix ]))
              ]))
              gettext
              po4a
            ];
            buildPhase = ''
              runHook preBuild
              po4a po4a.cfg
              emacs --batch -l ${org-to-html}
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -Dm644 configuration.html $out/index.html
              install -Dm644 configuration.ja.html $out/ja/index.html
              runHook postInstall
            '';
          };
      };
    };
}
