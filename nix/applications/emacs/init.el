(set-face-attribute 'default nil
                    :family "Liga HackGen Console NF"
                    :height 140)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(add-to-list 'default-frame-alist
'(undecorated-round . t))
(leaf doom-themes
  :ensure t
  :config
(load-theme 'doom-nord :no-confirm))
(setq-default indent-tabs-mode nil)
(leaf magit
  :ensure t
  :bind
(("C-x g" . magit-status)))
(leaf nix-mode
  :ensure t
  :mode "\\.nix\\'")
(require 'org-tempo)
