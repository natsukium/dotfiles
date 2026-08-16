;;; org-code-review-tests.el --- Tests for org-code-review  -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with:
;;
;;   emacs -Q --batch -L . -l org-code-review.el -l org-code-review-tests.el \
;;         -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'org-code-review)

;;;; Fixtures

(defun org-code-review-tests--project (files)
  "Create a git project containing FILES, an alist of (PATH . CONTENT).
Return the project root."
  (let ((root (file-name-as-directory
               (make-temp-file "org-code-review-test" t))))
    (let ((default-directory root))
      (call-process "git" nil nil nil "init" "-q"))
    (pcase-dolist (`(,path . ,content) files)
      (let ((file (expand-file-name path root)))
        (make-directory (file-name-directory file) t)
        (with-temp-file file (insert content))))
    root))

(defun org-code-review-tests--cleanup (root)
  "Kill every buffer visiting a file under ROOT, then delete ROOT."
  (dolist (buffer (buffer-list))
    (let ((file (buffer-file-name buffer)))
      (when (and file (string-prefix-p root (expand-file-name file)))
        (set-buffer-modified-p nil)
        (kill-buffer buffer))))
  (delete-directory root t))

(defmacro org-code-review-tests--with-project (files &rest body)
  "Evaluate BODY in a fresh project built from FILES.
Binds `root' to the project root and `review' to its review file."
  (declare (indent 1) (debug (form body)))
  `(let* ((root (org-code-review-tests--project ,files))
          (review (expand-file-name org-code-review-file-name root))
          ;; Every test gets its own cache, so none can be read from another.
          (org-code-review--cache nil))
     (ignore review)
     (unwind-protect (progn ,@body)
       (org-code-review-tests--cleanup root))))

(defun org-code-review-tests--review (&rest entries)
  "Return the contents of a review file holding ENTRIES."
  (apply #'concat org-code-review-file-header entries))

(defconst org-code-review-tests--source
  (concat ";;; a.el\n"
          "(defun alpha ()\n"
          "  (let ((cfg (config)))\n"
          "    (message \"hi\")))\n"
          "\n"
          "(defun beta ()\n"
          "  (let ((cfg (config)))\n"
          "    (message \"bye\")))\n")
  "An Elisp file to hang review comments on.")

(defconst org-code-review-tests--literate
  (concat "#+TITLE: conf\n\n"
          "* org-capture\n\n"
          "Capture has to be free of decisions.\n\n"
          "#+NAME: my-block\n"
          "#+begin_src emacs-lisp\n"
          "(setq org-capture-templates nil)\n"
          "#+end_src\n\n"
          "** Triage\n"
          ":PROPERTIES:\n:CUSTOM_ID: triage\n:END:\n\n"
          "The inbox only works if TRIAGE is a real gate.\n")
  "An Org file to hang review comments on, as in a literate configuration.")

(defun org-code-review-tests--overlays ()
  "Return the review overlays in the current buffer."
  (seq-filter (lambda (overlay) (overlay-get overlay 'org-code-review))
              (overlays-in (point-min) (point-max))))

(defun org-code-review-tests--diagnostics ()
  "Return the review diagnostics the backend reports for this buffer."
  (let (reported)
    (org-code-review-flymake (lambda (diagnostics) (setq reported diagnostics)))
    reported))

;;;; Reading the review file

(ert-deftest org-code-review-test-parses-an-entry ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#A] Wrong config lookup\n"
             ":PROPERTIES:\n:CREATED: [2026-08-15 Sat]\n:END:\n"
             "[[file:src/a.el::(let ((cfg (config)))][src/a.el:7]]\n\n"
             "This resolves the wrong config.\nSecond line of the body.\n")))
    (let ((comment (car (org-code-review-comments review))))
      (should (equal (org-code-review-comment-file comment) "src/a.el"))
      (should (equal (org-code-review-comment-search comment)
                     "(let ((cfg (config)))"))
      (should (equal (org-code-review-comment-line comment) 7))
      (should (equal (org-code-review-comment-keyword comment) "OPEN"))
      (should (equal (org-code-review-comment-priority comment) "A"))
      (should (equal (org-code-review-comment-heading comment)
                     "Wrong config lookup"))
      (should (equal (org-code-review-comment-body comment)
                     "This resolves the wrong config.\nSecond line of the body.")))))

(ert-deftest org-code-review-test-selects-open-comments-about-this-file ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] mine\n[[file:src/a.el::defun alpha (][src/a.el:2]]\n"
             "\n* RESOLVED [#B] closed\n[[file:src/a.el::defun beta (][src/a.el:6]]\n"
             "\n* OPEN [#B] another file\n[[file:src/b.el::whatever][src/b.el:1]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (should (equal (mapcar #'org-code-review-comment-heading
                             (org-code-review--comments-for-buffer))
                     '("mine"))))))

;;;; Placing a comment back into the code

(ert-deftest org-code-review-test-line-hint-disambiguates ()
  "The anchor matches twice; the recorded line decides which one."
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] second one\n"
             "[[file:src/a.el::(let ((cfg (config)))][src/a.el:7]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (let ((comment (car (org-code-review--comments-for-buffer))))
        (should (equal (line-number-at-pos
                        (car (org-code-review--locate comment)))
                       7))))))

(ert-deftest org-code-review-test-reports-a-lost-anchor ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] gone\n[[file:src/a.el::defun gamma (][src/a.el:99]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (let ((comment (car (org-code-review--comments-for-buffer))))
        (should-not (org-code-review--locate comment)))
      (let ((diagnostic (car (org-code-review-tests--diagnostics))))
        (should (equal (flymake-diagnostic-beg diagnostic) (point-min)))
        (should (equal (flymake-diagnostic-text diagnostic) "gone (anchor lost)"))))))

(ert-deftest org-code-review-test-falls-back-to-the-line-without-a-search-string ()
  "A comment on a line Org cannot summarise still has its line number."
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] blank line\n[[file:src/a.el][src/a.el:5]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (let ((comment (car (org-code-review--comments-for-buffer))))
        (should (equal (line-number-at-pos
                        (car (org-code-review--locate comment)))
                       5))))))

;;;; Flymake

(ert-deftest org-code-review-test-maps-priority-onto-severity ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#A] high\n[[file:src/a.el::defun alpha (][src/a.el:2]]\n"
             "\n* OPEN [#B] middle\n[[file:src/a.el::defun beta (][src/a.el:6]]\n"
             "\n* OPEN [#C] low\n[[file:src/a.el::;;; a.el][src/a.el:1]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (should (equal (mapcar #'flymake-diagnostic-type
                             (org-code-review-tests--diagnostics))
                     '(org-code-review-error
                       org-code-review-warning
                       org-code-review-note))))))

(ert-deftest org-code-review-test-reports-when-flymake-was-already-on ()
  "lsp-mode turns Flymake on first, and the backend must still run."
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] mine\n[[file:src/a.el::defun alpha (][src/a.el:2]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (flymake-mode 1)
      (org-code-review-mode 1)
      (should (equal (length (seq-filter
                              (lambda (diagnostic)
                                (eq (flymake-diagnostic-type diagnostic)
                                    'org-code-review-warning))
                              (flymake-diagnostics)))
                     1)))))

;;;; Rendering

(ert-deftest org-code-review-test-renders-under-the-anchor-line ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] Wrong config lookup\n"
             "[[file:src/a.el::(let ((cfg (config)))][src/a.el:7]]\n\n"
             "This resolves the wrong config.\nSecond line of the body.\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (org-code-review-mode 1)
      (let ((overlays (org-code-review-tests--overlays)))
        (should (equal (length overlays) 1))
        (should (equal (line-number-at-pos (overlay-start (car overlays))) 7))
        (should (equal (substring-no-properties
                        (overlay-get (car overlays) 'after-string))
                       (concat "\n  │ Wrong config lookup"
                               "\n  │ This resolves the wrong config."
                               "\n  │ Second line of the body.")))))))

(ert-deftest org-code-review-test-toggles-rendering ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] mine\n[[file:src/a.el::defun alpha (][src/a.el:2]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (org-code-review-mode 1)
      (should (equal (length (org-code-review-tests--overlays)) 1))
      (let ((org-code-review-inline-comments t))
        (org-code-review-toggle-comments)
        (should (equal (length (org-code-review-tests--overlays)) 0))
        (org-code-review-toggle-comments)
        (should (equal (length (org-code-review-tests--overlays)) 1))))))

;;;; Commands

(ert-deftest org-code-review-test-resolves-the-comment-at-point ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] mine\n[[file:src/a.el::(let ((cfg (config)))][src/a.el:7]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (org-code-review-mode 1)
      (goto-char (point-min))
      (forward-line 6)
      (should (equal (org-code-review-comment-heading
                      (org-code-review-comment-at-point))
                     "mine"))
      (org-code-review-resolve)
      (should-not (org-code-review--comments-for-buffer))
      (should (equal (length (org-code-review-tests--overlays)) 0)))))

;;;; Capturing

(ert-deftest org-code-review-test-capture-target-creates-the-file ()
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source))
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (let ((org-capture-plist nil)
            (source (current-buffer)))
        (org-capture-put :original-buffer source)
        (org-code-review-capture-target)
        (should (equal (expand-file-name (buffer-file-name)) review))
        (should (equal (buffer-string) org-code-review-file-header))
        ;; Point off a heading is what tells Org to append at end of file.
        (should-not (org-at-heading-p))))))

(ert-deftest org-code-review-test-anchor-round-trips ()
  "What capture writes must find the line it was written from."
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org" . ,(org-code-review-tests--review)))
    (let (annotation)
      (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
        (goto-char (point-min))
        (forward-line 5)
        (let ((org-capture-plist nil))
          (org-capture-put :original-buffer (current-buffer))
          (setq annotation (org-code-review-annotation))))
      (should (equal annotation "[[file:src/a.el::defun beta (][src/a.el:6]]"))
      (with-temp-file review
        (insert (org-code-review-tests--review
                 "\n* OPEN [#B] round trip\n" annotation "\n")))
      (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
        (let ((comment (car (org-code-review--comments-for-buffer))))
          (should (equal (line-number-at-pos
                          (car (org-code-review--locate comment)))
                         6)))))))

;;;; Anchoring inside an Org file

(ert-deftest org-code-review-test-anchors-the-line-not-the-element ()
  "Org's own context function answers with the enclosing element instead."
  (org-code-review-tests--with-project
      `(("conf.org" . ,org-code-review-tests--literate))
    (cl-flet ((annotation-at
                (needle)
                (with-current-buffer (find-file-noselect
                                      (expand-file-name "conf.org" root))
                  (goto-char (point-min))
                  (search-forward needle)
                  (let ((org-capture-plist nil))
                    (org-capture-put :original-buffer (current-buffer))
                    (org-code-review-annotation)))))
      ;; Not the block's #+NAME, not the enclosing heading, not its CUSTOM_ID.
      (should (equal (annotation-at "(setq org-capture-templates")
                     "[[file:conf.org::setq org-capture-templates nil][conf.org:9]]"))
      (should (equal (annotation-at "The inbox only works")
                     (concat "[[file:conf.org::The inbox only works if TRIAGE"
                             " is a real gate.][conf.org:17]]")))
      (should (equal (annotation-at "* org-capture")
                     "[[file:conf.org::org-capture][conf.org:3]]")))))

(ert-deftest org-code-review-test-resolves-anchors-inside-an-org-file ()
  (org-code-review-tests--with-project
      `(("conf.org" . ,org-code-review-tests--literate)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] in the block\n"
             "[[file:conf.org::setq org-capture-templates nil][conf.org:9]]\n"
             "\n* OPEN [#B] in the prose\n"
             "[[file:conf.org::The inbox only works if TRIAGE is a real gate.]"
             "[conf.org:17]]\n"
             ;; The shape `org-store-link' produces inside an Org file.
             "\n* OPEN [#B] stored by org-store-link\n"
             "[[file:conf.org::#triage][conf.org:12]]\n")))
    (with-current-buffer (find-file-noselect (expand-file-name "conf.org" root))
      (should (equal (mapcar (lambda (comment)
                               (line-number-at-pos
                                (car (org-code-review--locate comment))))
                             (org-code-review--comments-for-buffer))
                     '(9 17 14))))))

;;;; Parsing must survive the hooks it runs from

(ert-deftest org-code-review-test-cold-visit-does-not-re-enter ()
  "Visiting the review file runs the hooks that ask to read it."
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] mine\n[[file:src/a.el::defun alpha (][src/a.el:2]]\n")))
    (global-org-code-review-mode 1)
    (unwind-protect
        (progn
          (should (find-file-noselect review))
          (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
            (should org-code-review-mode)
            (should (equal (length (org-code-review-tests--overlays)) 1))))
      (global-org-code-review-mode -1))))

(ert-deftest org-code-review-test-parses-without-the-element-cache ()
  "Org disables its element cache inside modification hooks."
  (org-code-review-tests--with-project
      `(("src/a.el" . ,org-code-review-tests--source)
        (".private/review.org"
         . ,(org-code-review-tests--review
             "\n* OPEN [#B] mine\n[[file:src/a.el::defun alpha (][src/a.el:2]]\n")))
    (let ((inhibit-modification-hooks t))
      (should (equal (length (org-code-review-comments review)) 1)))
    (setq org-code-review--cache nil)
    (with-current-buffer (find-file-noselect (expand-file-name "src/a.el" root))
      (combine-change-calls (point-min) (point-max)
        (should (equal (length (org-code-review-comments review)) 1))))))

(provide 'org-code-review-tests)
;;; org-code-review-tests.el ends here
