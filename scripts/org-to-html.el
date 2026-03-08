(require 'org)
(require 'htmlize)
(require 'nix-ts-mode)

(add-to-list 'org-src-lang-modes '("nix" . nix-ts))
(setq treesit-font-lock-level 4)

;; In batch mode, faces lack color attributes. Explicitly set
;; foreground colors so htmlize emits colored inline CSS.
(set-face-attribute 'font-lock-keyword-face nil :foreground "#5317ac")
(set-face-attribute 'font-lock-string-face nil :foreground "#2544bb")
(set-face-attribute 'font-lock-comment-face nil :foreground "#505050")
(set-face-attribute 'font-lock-function-name-face nil :foreground "#721045")
(set-face-attribute 'font-lock-function-call-face nil :foreground "#721045")
(set-face-attribute 'font-lock-variable-name-face nil :foreground "#00538b")
(set-face-attribute 'font-lock-variable-use-face nil :foreground "#005077")
(set-face-attribute 'font-lock-type-face nil :foreground "#005a5f")
(set-face-attribute 'font-lock-constant-face nil :foreground "#0000c0")
(set-face-attribute 'font-lock-builtin-face nil :foreground "#8f0075")
(set-face-attribute 'font-lock-property-name-face nil :foreground "#00538b")
(set-face-attribute 'font-lock-property-use-face nil :foreground "#005077")
(set-face-attribute 'font-lock-number-face nil :foreground "#0000c0")
(set-face-attribute 'font-lock-operator-face nil :foreground "#813e00")
(set-face-attribute 'font-lock-bracket-face nil :foreground "#5f5f5f")
(set-face-attribute 'font-lock-delimiter-face nil :foreground "#5f5f5f")
(set-face-attribute 'font-lock-punctuation-face nil :foreground "#5f5f5f")
(set-face-attribute 'font-lock-escape-face nil :foreground "#a0132f")

(find-file "configuration.org")
(org-html-export-to-html)

(find-file "configuration.ja.org")
(org-html-export-to-html)
