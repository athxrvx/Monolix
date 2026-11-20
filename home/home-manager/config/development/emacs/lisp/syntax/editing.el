;;; editing.el --- Sane editor and navigation defaults -*- lexical-binding: t; -*-

;; Auto-save cursor position
(save-place-mode 1)

;; Track recently opened files
(recentf-mode 1)
(setq recentf-max-saved-items 200
      recentf-max-menu-items 15)

;; Sane spacing and tabs (2 spaces for indentation)
(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 80)

;; Auto-pair parentheses and quotes
(electric-pair-mode 1)

;; Highlight matching parentheses
(show-paren-mode 1)
(setq show-paren-delay 0)

;; Move through CamelCase words naturally
(global-subword-mode 1)

;; Sane backup and auto-save configuration
(setq backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-saves" user-emacs-directory) t))
      create-lockfiles nil
      make-backup-files t
      version-control t
      kept-old-versions 2
      kept-new-versions 6
      delete-old-versions t)

;; Undo-fu for Vim undo/redo compatibility
(use-package undo-fu
  :config
  (setq undo-limit 67108864      ; 64mb
        undo-strong-limit 100663296 ; 96mb
        undo-outer-limit 1006632960)) ; 960mb

;; Sane defaults for display line numbers (relative)
(setq-default display-line-numbers-width 3
              display-line-numbers-type 'relative)

;; Disable line numbers in special/text buffers
(dolist (hook '(term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                org-mode-hook
                markdown-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

;; Satisfying editing visual feedback
(use-package evil-goggles
  :after evil
  :init
  (evil-goggles-mode)
  :config
  (setq evil-goggles-duration 0.2))

;; Highlight TODO/FIXME/etc. in code
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"   . "#FF6C6B")
          ("FIXME"  . "#FF6C6B")
          ("DEBUG"  . "#C678DD")
          ("HACK"   . "#ECBECE")
          ("REWRITE". "#51AFEF")
          ("REVIEW" . "#98BE65")
          ("NOTE"   . "#ECBE7B"))))

;; Color hex values (like #ff0000)
(use-package rainbow-mode
  :hook (prog-mode . rainbow-mode))

;; Flash cursor on scroll and switch window
(use-package beacon
  :init
  (beacon-mode 1)
  :config
  (setq beacon-color "#81A1C1"
        beacon-blink-delay 0.1
        beacon-size 15))

(provide 'syntax/editing)
;;; editing.el ends here
