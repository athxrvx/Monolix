;;; citation.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Citation Variables
(defcustom lem-bibliography nil "User bibliography for citation."
  :group 'lambda-emacs
  :tag "Lambda-Emacs User Bibliography")
(defcustom lem-bib-notes nil "User citation notes directory."
  :group 'lambda-emacs
  :tag "Lambda-Emacs Citation Notes Directory")
(defcustom lem-citar-note nil "Template for use with citar notes."
  :group 'lambda-emacs
  :tag "Lambda-Emacs Citar Notes Template")

;;;; Org-Cite
;; Eventually this should be a full replacement for org-ref
(use-package oc
  :ensure nil
  :after org
  :config
  (setq org-cite-global-bibliography `(,lem-bibliography))
  (setq org-cite-export-processors
        '((beamer csl)
          (latex csl)
          (t csl))))

;; Use csl
(use-package oc-csl
  :ensure nil
  :defer t  ;; Defer loading until actually needed
  :commands (org-cite-csl-activate
             org-cite-csl-render-bibliography
             org-cite-csl-render-item)
  :init
  ;; Set these variables early so they're available when needed
  (with-eval-after-load 'oc
    ;; make sure to download csl
    ;; https://citationstyles.org
    ;; https://github.com/citation-style-language
    ;; repos for styles & locales
    (setq org-cite-csl-styles-dir "~/.local/share/csl/styles")
    (setq org-cite-csl-locales-dir "~/.local/share/csl/locales")))

;;;; Citeproc
(use-package citeproc
  :when (and lem-load-extras (locate-library "citeproc"))
  :defer t  ;; Defer loading until oc-csl needs it
  :after oc)

;;;; Citar
(use-package citar
  :when (and lem-load-extras (locate-library "citar"))
  :commands (citar-open-beref
             citar-open-notes
             citar-insert-citation)
  :bind (:map citar-map
         ("b" .  #'citar-open-beref))
  :custom
  ;; Use with org citation
  (org-cite-global-bibliography `(,lem-bibliography))
  (citar-bibliography `(,lem-bibliography))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar)
  :config
  ;; use embark with at-point
  (setq citar-at-point-function 'embark-act)
  ;; add beref entry for bookends
  (setq citar-additional-fields '("doi" "url"))
  (setq citar-templates
        `((main . " ${=key= id:15} ${title:48}")
          (suffix . "${author editor:30}  ${=type=:12}  ${=beref=:12} ${tags keywords:*}")
          (preview . "${author editor} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
          (note . ,lem-citar-note)))
  (when (display-graphic-p)
    ;; nerd-icons has no octicon PDF/text glyph, so those two use
    ;; FontAwesome; link-external maps to the octicon directly.
    (setq citar-symbols
          `((file ,(nerd-icons-faicon  "nf-fa-file_pdf_o"     :face 'error)   . " ")
            (note ,(nerd-icons-faicon  "nf-fa-file_text_o"    :face 'warning) . " ")
            (link ,(nerd-icons-octicon "nf-oct-link_external" :face 'org-link) . " "))))
  ;; edit notes
  (setq citar-notes-paths `(,lem-bib-notes)))

(provide 'component/citation)
;;; lem-setup-citation.el ends here
