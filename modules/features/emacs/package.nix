{
  stdenv,
  age,
  beancount,
  beancount-language-server,
  emacs-pgtk,
  emacs-plus,
  emacsWithPackagesFromUsePackage,
  gettext,
  nixd,
  nixfmt,
  notmuch,
  terraform-ls,
  yaml-language-server,
  defaultInitFile,
  org-clickup-src,
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
    };
  extraEmacsPackages = epkgs: [
    epkgs.treesit-grammars.with-all-grammars
    notmuch.emacs
    age
    beancount
    beancount-language-server
    gettext
    nixd
    nixfmt
    yaml-language-server
    terraform-ls
  ];
}
