;;; org.el --- Org-mode visual alignments -*- lexical-binding: t; -*-

(require 'org)
(require 'syntax/outer-indent)
(require 'syntax/margin)

;; Supporting packages for Rougier's visual minor modes
(use-package svg-tag-mode
  :straight t)

(use-package stripes
  :straight t)

;; Notebook Mode - Jupyter-like visual cells for code and results
(use-package notebook
  :straight (notebook-mode :type git :host github :repo "rougier/notebook-mode")
  :commands notebook-mode
  :config
  (setq notebook-hide-blocks nil))

;; Book Mode - elegant reading layout with margins and headers/footers
(use-package book-mode
  :straight (book-mode :type git :host github :repo "rougier/book-mode")
  :commands book-mode)

;; Notes List - two-line summary dashboard for all org notes
(use-package notes-list
  :straight (notes-list :type git :host github :repo "rougier/notes-list")
  :commands notes-list
  :config
  (setq notes-list-directories (list (expand-file-name "~/.orgfiles/"))))

(defcustom my-org-toolbar-auto-trigger nil
  "If non-nil, automatically open `my-org-toolbar' for Org files in `~/.orgfiles/'."
  :type 'boolean
  :group 'org)

(defcustom my-org-toolbar-auto-directory (expand-file-name "~/.orgfiles/")
  "Directory root where opening Org files auto-triggers the Org toolbar."
  :type 'directory
  :group 'org)

(defvar-local my-org-toolbar--auto-opened nil
  "Non-nil once the Org toolbar has been auto-opened for this buffer.")

(defun my-org-buffer-setup ()
  "Apply functional and aesthetic defaults for Org buffers."
  (setq-local line-spacing 0.12
              truncate-lines nil
              fill-column 90)
  (visual-line-mode 1)
  (when (fboundp 'hl-line-mode)
    (hl-line-mode 1))
  (when (fboundp 'org-display-inline-images)
    (org-display-inline-images t t)))

(defun my-org--file-in-auto-toolbar-directory-p ()
  "Return non-nil when current buffer file is under `my-org-toolbar-auto-directory'."
  (let ((file (buffer-file-name)))
    (and file
         (string-prefix-p
          (file-name-as-directory (expand-file-name my-org-toolbar-auto-directory))
          (expand-file-name file)))))

(defun my-org-maybe-auto-toolbar ()
  "Open `my-org-toolbar' automatically for Org files under `~/.orgfiles/'."
  (when (and my-org-toolbar-auto-trigger
             (not my-org-toolbar--auto-opened)
             (derived-mode-p 'org-mode)
             (my-org--file-in-auto-toolbar-directory-p))
    (setq-local my-org-toolbar--auto-opened t)
    (run-with-idle-timer
     0.05 nil
     (lambda (buffer)
       (when (buffer-live-p buffer)
         (with-current-buffer buffer
           (when (and (derived-mode-p 'org-mode)
                      (my-org--file-in-auto-toolbar-directory-p))
             (my-org-toolbar)))))
     (current-buffer))))

(use-package org
  :straight nil
  :hook
  ;; Enable outer indentation by default
  (org-mode . outer-indent-mode)
  (org-mode . my-org-buffer-setup)
  :config
  ;; Base directory and files for Org task management
  (setq org-directory (expand-file-name "~/.orgfiles/"))
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))
  (setq org-default-notes-file (expand-file-name "todo.org" org-directory))
  (setq org-agenda-files (list org-directory))

  ;; Custom TODO states
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "HOLD(h)" "|" "DONE(d)" "CANCELED(c)")))

  ;; Sane settings for task management
  (setq org-ellipsis " ▾"
        org-auto-align-tags nil
        org-tags-column 0
        org-cycle-separator-lines 1
        org-fontify-done-headline t
        org-fontify-quote-and-verse-blocks t
        org-fontify-whole-heading-line t
        org-hide-emphasis-markers t
        org-hide-leading-stars t
        org-image-actual-width '(520)
        org-log-into-drawer t
        org-log-done 'time
        org-pretty-entities t
        org-return-follows-link t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-window-setup 'current-window
        org-startup-indented t
        org-startup-folded t
        org-startup-with-inline-images t
        org-fold-catch-invisible-edits 'show-and-error)

  (setq margin-headers-set 'H-txt)

  ;; Custom Agenda Dashboard View
  (setq org-agenda-custom-commands
        '(("d" "Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-agenda-start-on-weekday nil)
                        (org-agenda-start-day "today")))
            (todo "NEXT" ((org-agenda-overriding-header "⚡ Next Actions")))
            (todo "TODO" ((org-agenda-overriding-header "📋 Inbox / Unsorted Tasks")))
            (todo "HOLD" ((org-agenda-overriding-header "⏳ On Hold")))))))

  ;; Quick Capture Templates
  (setq org-capture-templates
        '(("t" "Todo Task" entry
           (file+headline (lambda () (expand-file-name "todo.org" org-directory)) "Inbox")
           "* TODO %?\n  Created: %U\n  %i" :empty-lines 1)
          ("n" "Next Action" entry
           (file+headline (lambda () (expand-file-name "todo.org" org-directory)) "Inbox")
           "* NEXT %?\n  Created: %U\n  %i" :empty-lines 1)))

  ;; Align headings visually with Nano style
  (custom-theme-set-faces
   'user
   `(org-level-1 ((t (:inherit theme-face-strong :height 1.15 :weight bold))))
   `(org-level-2 ((t (:inherit theme-face-strong :height 1.1 :weight regular))))
   `(org-level-3 ((t (:inherit theme-face-strong :height 1.05 :weight regular))))
   `(org-level-4 ((t (:inherit theme-face-strong :height 1.0 :weight regular))))
   `(org-document-title ((t (:inherit theme-face-strong :height 1.25 :weight bold))))
   `(org-document-info-keyword ((t (:inherit theme-face-faded :height 0.95))))
   `(org-meta-line ((t (:inherit theme-face-faded :height 0.95))))
   `(org-block ((t (:inherit fixed-pitch :background ,theme-color-subtle :extend t))))
   `(org-table ((t (:inherit fixed-pitch))))
   `(org-code ((t (:inherit (fixed-pitch theme-face-popout)))))
   `(org-verbatim ((t (:inherit (fixed-pitch theme-face-popout))))))
  (add-hook 'org-babel-after-execute-hook #'org-redisplay-inline-images))

;; Modern styling for Org-mode
(use-package org-modern
  :hook
  ((org-mode . org-modern-mode)
   (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-star '("◉" "○" "✸" "✿" "✤" "✜" "◆" "▲")
        org-modern-list '((?- . "•") (?+ . "◦"))
        org-modern-todo t
        org-modern-table t
        org-modern-tag t
        org-modern-block-name nil
        org-modern-keyword nil
        org-modern-checkbox '((?X . "☑")
                              (?\s . "☐")
                              (?- . "[-]")))
  (set-face-attribute 'org-modern-symbol nil :family "JetBrainsMono Nerd Font"))

;; Safe margins vs indentation switcher
(defun my-org-toggle-margin-or-indent ()
  "Toggle between margin-mode and outer-indent-mode."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an Org buffer"))
  (if margin-mode
      (progn
        (margin-mode -1)
        (outer-indent-mode 1)
        (message "Switched to Org Outer Indent Mode"))
    (progn
      (outer-indent-mode -1)
      (when (and (boundp 'org-indent-mode) org-indent-mode)
        (org-indent-mode -1))
      (margin-mode 1)
      (message "Switched to Org Margin Mode"))))

(defun my-org-toolbar ()
  "Open an interactive NΛNO toolbar for Org actions in the header line."
  (interactive)
  (require 'ui/toolbar)
  (let* ((choices '(( "Margin"    . default )
                    ( "Notebook"  . default )
                    ( "Book"      . default )
                    ( "Writer"    . default )
                    ( "Sidebar"   . default )
                    ( "Agenda"    . default )
                    ( "Notes"     . default )
                    ( "Capture"   . default )
                    ( "Journal"   . default )
                    ( "Dashboard" . default )
                    ( "Box"       . default )
                    ( "Export"    . default )
                    ( "Roam Find" . default )
                    ( "Roam Link" . default )
                    ( "Roam Graph". default )
                    ( "Roam Daily". default )
                    ( "Roam Backs". default )))
         (choice (boba-toolbar "Org Action:" choices)))
    (cond
     ((string= choice "Margin")   (call-interactively 'my-org-toggle-margin-or-indent))
     ((string= choice "Notebook") (call-interactively 'notebook-mode))
     ((string= choice "Book")     (call-interactively 'book-mode))
     ((string= choice "Writer")   (call-interactively 'my-toggle-writer-mode))
     ((string= choice "Sidebar")  (call-interactively 'boba-sidebar-toggle-org))
     ((string= choice "Agenda")   (call-interactively 'boba-agenda))
     ((string= choice "Notes")    (call-interactively 'notes-list))
     ((string= choice "Capture")  (call-interactively 'org-capture))
     ((string= choice "Journal")  (call-interactively 'boba-journal))
     ((string= choice "Dashboard")(call-interactively 'dashboard-splash))
     ((string= choice "Box")      (call-interactively 'boba-box))
     ((string= choice "Export")   (call-interactively 'org-export-dispatch))
     ((string= choice "Roam Find") (call-interactively 'org-roam-node-find))
     ((string= choice "Roam Link") (call-interactively 'org-roam-node-insert))
     ((string= choice "Roam Graph") (call-interactively 'org-roam-ui-mode))
     ((string= choice "Roam Daily") (call-interactively 'org-roam-dailies-goto-today))
     ((string= choice "Roam Backs") (call-interactively 'boba-sidebar-toggle-org)))))

;; Map Org toggle keybinds in evil
(with-eval-after-load 'general
  (general-define-key
   :states '(normal)
   :keymaps 'org-mode-map
   "SPC t o" 'my-org-toggle-margin-or-indent
   "SPC t a" 'my-org-toolbar
   "SPC o o" 'my-org-toolbar
   "SPC o a" 'boba-agenda
   "SPC o c" 'org-capture
   "SPC o j" 'boba-journal
   "SPC o n" 'notes-list
   "SPC o s" 'boba-sidebar-toggle-org
   "SPC o w" 'my-toggle-writer-mode
   
   ;; Additional Org-roam keys under SPC o
   "SPC o r f" 'org-roam-node-find
   "SPC o r i" 'org-roam-node-insert
   "SPC o r g" 'org-roam-ui-mode
   "SPC o r d" 'org-roam-dailies-goto-today
   "SPC o r b" 'boba-sidebar-toggle-org))

(provide 'syntax/org)
;;; org.el ends here
