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
              patchShebangs scripts
              scripts/build-html.sh --output build
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -r build/. $out/
              runHook postInstall
            '';
          };
      };
    };
}
