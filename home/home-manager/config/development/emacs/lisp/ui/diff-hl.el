;;; diff-hl.el --- Git fringe diff indicators -*- lexical-binding: t; -*-

(use-package diff-hl
  :hook
  ((prog-mode . diff-hl-mode)
   (org-mode . diff-hl-mode)
   (dired-mode . diff-hl-dired-mode))
  :config
  ;; Update fringe indicators immediately on save
  (add-hook 'after-save-hook #'diff-hl-update)
  ;; Make indicators look subtle and clean
  (diff-hl-margin-mode -1)
  (diff-hl-flydiff-mode 1))

(provide 'ui/diff-hl)
;;; diff-hl.el ends here
