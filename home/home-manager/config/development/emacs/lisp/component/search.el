;;; search.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;; Search

;;;; Deadgrep
;; Deadgrep uses ripgrep for extremely fast text searches and provides a
;; separate buffer for results.
(use-package deadgrep
  :when (and lem-load-extras (locate-library "deadgrep"))
  :bind (:map lem+search-keys
         ("g" . deadgrep)))

;;;; Ripgrep
;; Ripgrep is a replacement for both grep like (search one file) and ag like
;; (search many files) tools. It's fast and versatile and written in Rust.
(use-package rg
  :when (and lem-load-extras (locate-library "rg")) :commands rg)

;;;; Xref
;; Built-in library for cross-referencing
(use-package xref
  :ensure nil
  :defer 1)

;;;; Search and Replace
(use-package visual-regexp
  :when (and lem-load-extras (locate-library "visual-regexp"))
  :commands (vr/query-replace)
  :config
  (use-package visual-regexp-steroids
    :when (and lem-load-extras (locate-library "visual-regexp-steroids"))
    :commands (vr/select-query-replace)))


;;; Provide
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'component/search)
;;; lem-setup-search.el ends here
