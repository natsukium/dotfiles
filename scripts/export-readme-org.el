(require 'ox-org)

(defun export-if-changed (destination)
  ;; Exporting directly rewrites the README even when its content is unchanged.
  ;; po4a uses mtimes to decide whether its source needs regeneration, so keep
  ;; the destination's mtime stable when the exported bytes are identical.
  (let ((temporary (make-temp-file "org-export-")))
    (unwind-protect
        (progn
          (org-export-to-file 'org temporary)
          (if (and (file-exists-p destination)
                   (with-temp-buffer
                     (insert-file-contents-literally destination)
                     (let ((destination-content (buffer-string)))
                       (erase-buffer)
                       (insert-file-contents-literally temporary)
                       (equal destination-content (buffer-string)))))
              (delete-file temporary)
            (set-file-modes temporary (if (file-exists-p destination) (file-modes destination) #o644))
            (rename-file temporary destination t)
            (setq temporary nil)))
      (when (file-exists-p temporary)
        (delete-file temporary)))))

(let ((org-export-select-tags (list "readme"))
      (org-export-with-author nil)
      (org-export-with-tags nil)
      (org-export-time-stamp-file nil))
  (export-if-changed export-readme-dest))
