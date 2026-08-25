{
  stdenv,
  age,
  beancount,
  beancount-language-server,
  difftastic,
  emacs31-pgtk,
  emacs31-plus,
  emacsWithPackagesFromUsePackage,
  gettext,
  nixd,
  nixfmt,
  terraform-ls,
  yaml-language-server,
  org-clickup-src,
}:
let
  emacs-unwrapped = if stdenv.hostPlatform.isDarwin then emacs31-plus else emacs31-pgtk;
in
emacsWithPackagesFromUsePackage {
  package = emacs-unwrapped;
  config = ./init.org;
  alwaysTangle = true;
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
