(set-face-attribute 'default nil
                    :family "Liga HackGen Console NF"
                    :height 140)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(add-to-list 'default-frame-alist
'(undecorated-round . t))
(use-package doom-themes
  :ensure t
  :config
  (load-theme 'doom-nord :no-confirm))

(which-key-mode)

(use-package magit
  :ensure t
  :bind
  (("C-x g" . magit-status)))

(setq-default indent-tabs-mode nil)

(require 'org-tempo)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((shell . t)))

(setq org-src-preserve-indentation t)

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/dropbox/org-roam")
  (org-roam-db-location "~/.local/share/org-roam.db")
  :bind
  (("C-c n l" . org-roam-buffer-toggle)
   ("C-c n f" . org-roam-node-find)
   ("C-c n g" . org-roam-graph)
   ("C-c n i" . org-roam-node-insert)
   ("C-c n c" . org-roam-capture)
   ("C-c n j" . org-roam-dailies-capture-today))
  :config
  (setq org-roam-node-display-template
        (concat "${title:*} "
                (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode)
  (require 'org-roam-protocol)
  )

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'")
