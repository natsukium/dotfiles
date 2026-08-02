{
  stdenv,
  age,
  beancount,
  beancount-language-server,
  difftastic,
  emacs-pgtk,
  emacs-plus,
  emacsWithPackagesFromUsePackage,
  fetchFromGitHub,
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
      lean4-mode = epkgs.melpaBuild rec {
        pname = "lean4-mode";
        ename = "lean4-mode";
        version = "1.1.2";
        commit = "76895d8939111654a472cfc617cfd43fbf5f1eb6";
        # lean4-input reads data/abbreviations.json from next to its own .el
        files = ''("*.el" "data")'';
        src = fetchFromGitHub {
          owner = "leanprover-community";
          repo = "lean4-mode";
          tag = version;
          hash = "sha256-DLgdxd0m3SmJ9heJ/pe5k8bZCfvWdaKAF0BDYEkwlMQ=";
        };
        packageRequires = with epkgs; [
          compat
          dash
          lsp-mode
          magit-section
        ];
      };
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
    difftastic
    gettext
    nixd
    nixfmt
    yaml-language-server
    terraform-ls
  ];
}
