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
        fastfetch = pkgs.callPackage ../../pkgs/fastfetch { };
        html =
          with pkgs;
          let
            org-to-html = ../../scripts/org-to-html.el;
          in
          stdenvNoCC.mkDerivation {
            name = "dotfiles";
            src = lib.cleanSource ../..;
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
