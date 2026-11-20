;;; projects.el --- Workspace and Git management -*- lexical-binding: t; -*-

;; Built-in project.el settings
(use-package project
  :straight nil
  :config
  (setq project-vc-merges-limit 100))

;; Magit for Git management
(use-package magit
  :commands magit-status
  :init
  (setq magit-refresh-status-buffer nil)
  :config
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(provide 'navigation/projects)
;;; projects.el ends here
