{
  runCommand,
  stdenv,
  age,
  beancount,
  beancount-language-server,
  difftastic,
  emacs-pgtk,
  emacs-plus,
  emacsWithPackagesFromUsePackage,
  gettext,
  git,
  nixd,
  nixfmt,
  terraform-ls,
  yaml-language-server,
  defaultInitFile,
  org-clickup-src,
  org-code-review-el,
  org-code-review-tests,
}:
let
  emacs-unwrapped = if stdenv.hostPlatform.isDarwin then emacs-plus else emacs-pgtk;
in
emacsWithPackagesFromUsePackage {
  package = emacs-unwrapped;
  config = ./init.org;
  alwaysTangle = true;
  # Bundle the tangled init.org as default.el so the package is usable
  # standalone (e.g. `nix run .#emacs`); a home-manager-managed
  # ~/.config/emacs/init.el still takes precedence when present.
  inherit defaultInitFile;
  override =
    epkgs:
    epkgs
    // {
      org-clickup = epkgs.melpaBuild {
        pname = "org-clickup";
        ename = "org-clickup";
        version = builtins.substring 0 8 (org-clickup-src.lastModifiedDate or "00000000");
        commit = org-clickup-src.shortRev or "unknown";
        files = ''("lisp/*.el")'';
        src = org-clickup-src;
      };

      # Building the review library as a package rather than tangling it into
      # the init byte-compiles it, which the init itself is not: the tangled
      # default.el carries no lexical-binding cookie, so everything in it runs
      # under dynamic binding.
      org-code-review = epkgs.trivialBuild {
        pname = "org-code-review";
        version = "0.1.0";
        src = runCommand "org-code-review-src" { } ''
          mkdir -p $out
          cp ${org-code-review-el} $out/org-code-review.el
          cp ${org-code-review-tests} $out/org-code-review-tests.el
        '';
        # The suite runs as part of the build rather than as a separate check,
        # so a regression cannot reach a rebuilt system by being forgotten.
        # git is here because the tests need a project for `project-current'.
        nativeCheckInputs = [ git ];
        doCheck = true;
        checkPhase = ''
          runHook preCheck
          emacs -Q --batch -L . -l org-code-review.el \
            -l org-code-review-tests.el -f ert-run-tests-batch-and-exit
          runHook postCheck
        '';
        # The tests are not part of what gets loaded.
        postInstall = "rm -f $out/share/emacs/site-lisp/org-code-review-tests.el*";
        meta.description = "Review comments about code, kept in Org";
      };
    };
  extraEmacsPackages = epkgs: [
    epkgs.treesit-grammars.with-all-grammars
    age
    beancount
    beancount-language-server
    difftastic
    gettext
    nixd
    nixfmt
    yaml-language-server
    terraform-ls
  ];
}
