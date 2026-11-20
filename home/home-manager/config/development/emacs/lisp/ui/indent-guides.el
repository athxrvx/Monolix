;;; indent-guides.el --- Visual indentation guides -*- lexical-binding: t; -*-

(use-package highlight-indent-guides
  :hook
  (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-method 'character)
  (highlight-indent-guides-responsive 'selected)
  (highlight-indent-guides-character ?│) ; nice thin vertical line
  (highlight-indent-guides-auto-enabled t)
  :config
  ;; Adjust colors subtly to fit the theme
  (setq highlight-indent-guides-auto-even-character-face-percent 10
        highlight-indent-guides-auto-odd-character-face-percent 10))

(provide 'ui/indent-guides)
;;; indent-guides.el ends here
