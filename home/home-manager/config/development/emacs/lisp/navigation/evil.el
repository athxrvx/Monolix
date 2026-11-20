;;; evil.el --- Vim emulation and leader keybindings -*- lexical-binding: t; -*-

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil) ; Required by evil-collection
  (setq evil-want-C-i-jump t)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-d-scroll t)
  (setq evil-undo-system 'undo-fu)
  :config
  (evil-mode 1)
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-set-initial-state 'dashboard-mode 'normal))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; General.el leader bindings setup
(use-package general
  :after evil
  :config
  (general-evil-setup t)

  ;; Define 'SPC' as the global leader key
  (general-create-definer my-leader
    :states '(normal insert visual motion)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  ;; Root / Global bindings
  (my-leader
    "SPC" '(execute-extended-command :which-key "M-x")
    "u"   '(universal-argument :which-key "Universal arg"))

  ;; Buffers (SPC b ...)
  (my-leader
    "b"   '(:ignore t :which-key "buffers")
    "b b" '(consult-buffer :which-key "Switch buffer")
    "b k" '(kill-current-buffer :which-key "Kill buffer")
    "b n" '(next-buffer :which-key "Next buffer")
    "b p" '(previous-buffer :which-key "Previous buffer")
    "b s" '(scratch-buffer :which-key "Scratch buffer"))

  ;; Files (SPC f ...)
  (my-leader
    "f"   '(:ignore t :which-key "files")
    "f f" '(find-file :which-key "Find file")
    "f s" '(save-buffer :which-key "Save file")
    "f r" '(consult-recent-file :which-key "Recent files")
    "f p" '((lambda () (interactive) (find-file (expand-file-name "init.el" user-emacs-directory))) :which-key "Open init.el"))

  ;; Projects (SPC p ...)
  (my-leader
    "p"   '(:ignore t :which-key "projects")
    "p p" '(project-switch-project :which-key "Switch project")
    "p f" '(project-find-file :which-key "Find file in project")
    "p d" '(project-dired :which-key "Project Dired"))

  ;; Search (SPC s ...)
  (my-leader
    "s"   '(:ignore t :which-key "search")
    "s s" '(consult-line :which-key "Search line")
    "s g" '(consult-ripgrep :which-key "Ripgrep in project"))

  ;; Windows (SPC w ...)
  (my-leader
    "w"   '(:ignore t :which-key "windows")
    "w w" '(other-window :which-key "Other window")
    "w s" '(split-window-below :which-key "Split horizontal")
    "w v" '(split-window-right :which-key "Split vertical")
    "w c" '(delete-window :which-key "Delete window")
    "w o" '(delete-other-windows :which-key "Maximize window"))

  ;; Git (SPC g ...)
  (my-leader
    "g"   '(:ignore t :which-key "git")
    "g g" '(magit-status :which-key "Magit Status"))

  ;; Code (SPC c ...)
  (my-leader
    "c"   '(:ignore t :which-key "code")
    "c a" '(eglot-code-actions :which-key "LSP code actions")
    "c r" '(eglot-rename :which-key "LSP rename symbol")
    "c f" '(eglot-format :which-key "Format code")
    "c d" '(xref-find-definitions :which-key "Find definition")
    "c u" '(xref-find-references :which-key "Find references"))

  ;; Org (SPC o ...)
  (my-leader
    "o"   '(:ignore t :which-key "org")
    "o a" '(org-agenda :which-key "Org Agenda")
    "o d" '((lambda () (interactive) (org-agenda nil "d")) :which-key "Agenda Dashboard")
    "o c" '(org-capture :which-key "Org Capture")
    "o n" '(notes-list :which-key "Notes list dashboard")
    "o t" '((lambda () (interactive) (find-file (expand-file-name "todo.org" org-directory))) :which-key "Open Todo File"))

  ;; Toggles (SPC t ...)
  (my-leader
    "t"   '(:ignore t :which-key "toggles")
    "t t" '(theme-toggle :which-key "Toggle theme")
    "t l" '(display-line-numbers-mode :which-key "Toggle line numbers")
    "t o" '(my-org-toggle-margin-or-indent :which-key "Toggle Org margins")
    "t n" '(notebook-mode :which-key "Toggle Notebook Mode")
    "t b" '(book-mode :which-key "Toggle Book reading mode")
    "t w" '(my-toggle-writer-mode :which-key "Toggle Writer Mode")
    "t s" '(boba-sidebar-toggle :which-key "Toggle right sidebar")
    "t a" '(my-org-toolbar :which-key "Org actions toolbar"))

  ;; Dashboard (SPC d ...)
  (my-leader
    "d"   '(:ignore t :which-key "dashboard")
    "d d" '(boba-dashboard-open :which-key "Open dashboard")))

(provide 'navigation/evil)
;;; evil.el ends here
