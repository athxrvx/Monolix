;;; sidebar.el --- BOBA sidebar -*- lexical-binding: t -*-

;; GNU Emacs / BOBA sidebar
;; Copyright (C) 2021 Nicolas P. Rougier
;; Modified in 2026 for BOBA theme sidebar dashboards.

;; Author: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; Homepage: https://github.com/rougier/boba-sidebar
;; Keywords: convenience
;; Version: 0.1

;; Package-Requires: ((emacs "26.1"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;;; Commentary:
;;
;; This package allows to have configurable sidebars on a per frame basis.
;; It integrates the standard ibuffer layout configuration as the default init.
;;

;;; Code:

(eval-when-compile
  (require 'neotree nil t))

(require 'ui/sidebar-dashboards)

(defvar neo-buffer-name)
(defvar neo-display-action)
(declare-function neotree-show "neotree")
(declare-function neo-global--get-window "neotree")
(declare-function ibuffer-auto-mode "ibuffer")
(declare-function ibuffer-switch-to-saved-filter-groups "ibuf-ext")

(defgroup boba-sidebar nil
  "Sidebar"
  :group 'nano)

(defcustom boba-sidebar-default-width 36
  "Default sidebar width in characters"
  :type '(integer)
  :group 'boba-sidebar)

(defcustom boba-sidebar-default-mode nil
  "Default sidebar mode (light, dark, or nil to inherit)."
  :type '(choice (const :tag "Inherit" nil)
                 (const :tag "Light" light)
                 (const :tag "Dark"  dark))
  :group 'boba-sidebar)

(defcustom boba-sidebar-default-background nil
  "Default sidebar background color. If nil, dynamically uses theme-color-subtle."
  :type '(choice (const nil) (string))
  :group 'boba-sidebar)

(defcustom boba-sidebar-default-init 'boba-sidebar-init-neotree
  "Default sidebar initialization function."
  :type '(sexp)
  :group 'boba-sidebar)

(defcustom boba-sidebar-properties
  `(("default" 36 light nil boba-sidebar-init-neotree))
  "Individual properties of sidebars associated with parent frames."
  :type '(repeat (list (string   :tag "Parent name")
                        (integer  :tag "Sidebar width")
                        (symbol   :tag "Sidebar mode")
                        (choice   :tag "Sidebar background color" (const nil) (string))
                        (sexp     :tag "Sidebar initialization")))
  :group 'boba-sidebar)

(defun boba-sidebar-get-width (&optional frame)
  "Retrieve the width of the sidebar associated with frame."
  (let* ((name (frame-parameter frame 'name))
         (width boba-sidebar-default-width))
    (dolist (element boba-sidebar-properties)
      (if (string= name (nth 0 element))
          (setq width (nth 1 element))))
    width))

(defun boba-sidebar-get-mode (&optional frame)
  "Retrieve the mode of the sidebar associated with frame."
  (let* ((name (frame-parameter frame 'name))
         (mode (or boba-sidebar-default-mode
                   (and (boundp 'frame-background-mode) frame-background-mode)
                   'light)))
    (dolist (element boba-sidebar-properties)
      (if (string= name (nth 0 element))
          (setq mode (nth 2 element))))
    mode))

(defun boba-sidebar-get-background (&optional frame)
  "Retrieve the background color of the sidebar associated with frame."
  (let* ((name (frame-parameter frame 'name))
         (background (or boba-sidebar-default-background
                         (and (boundp 'theme-color-subtle) theme-color-subtle)
                         "#FCFBF9")))
    (dolist (element boba-sidebar-properties)
      (if (string= name (nth 0 element))
          (setq background (or (nth 3 element) background))))
    background))

(defun boba-sidebar-get-init (&optional frame)
  "Retrieve the initialization function of the sidebar associated with frame."
  (let* ((name (frame-parameter frame 'name))
         (init (or (frame-parameter frame 'sidebar-init)
                   boba-sidebar-default-init)))
    (dolist (element boba-sidebar-properties)
      (if (string= name (nth 0 element))
          (setq init (nth 4 element))))
    init))

(defun boba-sidebar-init (_frame sidebar)
  "Default sidebar initialization"
  (select-frame sidebar)
  (when (not (get-buffer "BOBA sidebar"))
    (switch-to-buffer "BOBA sidebar")
    (insert (concat 
             (propertize " "  'display `(raise +0.20))
             "         B O B A sidebar"
             (propertize " "  'display `(raise -0.15))
             "\n")))

  (switch-to-buffer "BOBA sidebar")
  (hl-line-mode)
  (setq header-line-format "")
  (face-remap-add-relative 'header-line
                           `(:box (:line-width 3
                                   :color ,(face-background 'default)
                                   :style nil)))
  (setq mode-line-format nil))
  
(defun boba-sidebar-create ()
  "Create a new sidebar frame"
  (setq default-minibuffer-frame (window-frame))
  
  (let* ((parent (window-frame))
         (sidebar-mode (boba-sidebar-get-mode parent))
         (sidebar-width (boba-sidebar-get-width parent))
         (sidebar-background (boba-sidebar-get-background parent))
         (sidebar-init (boba-sidebar-get-init parent))
         (char-width (frame-char-width parent))
         (sidebar-px-width (* sidebar-width char-width))
         (parent-px-width (frame-pixel-width parent))
         (left-px (- parent-px-width sidebar-px-width))
         ;; Sidebar spans full height of parent frame, starting at very top
         (sidebar-px-height (frame-pixel-height parent))
         
         (sidebar (make-frame `((parent-frame . ,parent)
                               (sidebar-p    . t)
                               (width        . ,sidebar-width)
                               (height       . ,sidebar-px-height)
                               (left         . ,left-px)
                               (top          . 0)
                               (no-accept-focus . nil)
                               (min-width  . t)
                               (min-height . t)
                               (border-width . 0)
                               (internal-border-width . 0)
                               (vertical-scroll-bars . nil)
                               (horizontal-scroll-bars . nil)
                               (left-fringe . 1)
                               (right-fringe . 0)
                               (user-position . nil)
                               (user-size . nil)
                               (keep-ratio . (height-only . nil))
                               (menu-bar-lines . 0)
                               (tool-bar-lines . 0)
                               (line-spacing . 0)
                               (desktop-dont-save . t)
                               (unsplittable . t)
                               (background-mode . ,sidebar-mode)
                               (background-color . ,sidebar-background)
                               (no-other-frame . t)
                               (undecorated . nil)
                               (pixelwise . t)
                               (modeline . nil)
                               (visibility . nil)
                               (cursor-type . nil)
                               (minibuffer . nil)))))

    (set-frame-parameter sidebar 'parent parent)
    (set-frame-parameter parent 'sidebar sidebar)

    (if sidebar-init
        (funcall sidebar-init parent sidebar))
    
    (select-frame parent)
    sidebar))

(defun boba-sidebar-write-debug-log (action)
  "Write diagnostic info to sidebar-debug.log."
  (let* ((parent (selected-frame))
         (sidebar (frame-parameter parent 'sidebar))
         (sidebar-exists (frame-live-p sidebar))
         (sidebar-visible (and sidebar-exists (frame-parameter sidebar 'visibility)))
         (sidebar-window (and sidebar-exists (frame-selected-window sidebar)))
         (sidebar-buffer (and sidebar-window (window-buffer sidebar-window)))
         (buffer-name (and sidebar-buffer (buffer-name sidebar-buffer)))
         (buffer-contents (and sidebar-buffer 
                               (with-current-buffer sidebar-buffer
                                 (buffer-substring-no-properties (point-min) (point-max)))))
         (log-file "/home/atharva/.config/emacs/sidebar-debug.log"))
    (with-temp-file log-file
      (insert (format "Action: %s\n" action))
      (insert (format "Time: %s\n" (current-time-string)))
      (insert (format "Sidebar Exists: %s\n" sidebar-exists))
      (insert (format "Sidebar Visible: %s\n" sidebar-visible))
      (insert (format "Sidebar Selected Window: %s\n" sidebar-window))
      (insert (format "Sidebar Buffer Name: %s\n" buffer-name))
      (insert (format "Sidebar Buffer Contents Length: %s\n" (and buffer-contents (length buffer-contents))))
      (insert "Sidebar Buffer Contents:\n")
      (insert (or buffer-contents "<nil>"))
      (insert "\n\nSidebar Parameters:\n")
      (when sidebar-exists
        (dolist (param '(left top width height visibility parent-frame sidebar-p))
          (insert (format "  %s: %s\n" param (frame-parameter sidebar param)))))
      (insert (format "\nneo-global--window: %s\n" (and (boundp 'neo-global--window) neo-global--window)))
      (insert (format "neo-global--window live?: %s\n" (and (boundp 'neo-global--window) (window-live-p neo-global--window))))
      (insert (format "neo-global--buffer: %s\n" (and (boundp 'neo-global--buffer) neo-global--buffer)))
      (insert (format "Last messages:\n%s\n"
                      (with-current-buffer (get-buffer-create "*Messages*")
                        (buffer-substring-no-properties (max 1 (- (point-max) 1000)) (point-max))))))))

(defun boba-sidebar-push-margins (parent width)
  "Set right margin on all parent frame windows to WIDTH columns."
  (walk-windows
   (lambda (w)
     (set-window-margins w 0 width))
   nil parent))

(defun boba-sidebar-clear-margins (parent)
  "Clear right margins on all parent frame windows."
  (walk-windows
   (lambda (w)
     (set-window-margins w 0 0))
   nil parent))

(defun boba-sidebar-toggle ()
  (interactive)
  (let* ((selected-frame (window-frame))
         (sidebar (frame-parameter nil 'sidebar))
         (sidebar-p (frame-parameter nil 'sidebar-p))
         (sidebar (if (frame-live-p sidebar) sidebar))
         (sidebar (if sidebar-p
                       (window-frame)
                     (or sidebar (boba-sidebar-create))))
         (parent (frame-parameter sidebar 'parent-frame))
         (sidebar-width (boba-sidebar-get-width parent))
         (visible (frame-parameter sidebar 'visibility)))

    (when visible
      (make-frame-invisible sidebar)
      (boba-sidebar-clear-margins parent))

    (when (not visible)
      (let* ((win (frame-selected-window parent))
             (hl-px  (or (window-header-line-height win) 0))
             (win-px (window-pixel-height win))
             ;; Sidebar spans full window height from top
             (sidebar-px-height win-px)
             (char-width (frame-char-width parent))
             (sidebar-px-width (* sidebar-width char-width))
             (parent-px-width (frame-pixel-width parent))
             (left-px (- parent-px-width sidebar-px-width)))
        (make-frame-visible sidebar)
        (modify-frame-parameters sidebar `((top    . 0)
                                           (height . ,win-px)
                                           (width  . ,sidebar-width)
                                           (left   . ,left-px)
                                           (pixelwise . t))))
      ;; Push all parent windows' content to the left so the sidebar
      ;; child frame only covers the reserved margin area, not the text.
      (boba-sidebar-push-margins parent sidebar-width)
      (select-frame-set-input-focus selected-frame))

    ;; Do not set frame-background-mode globally to avoid theme face resets
    (condition-case nil
        (boba-sidebar-write-debug-log (if visible "hide" "show"))
      (error nil))))

;; ==========================================
;; Ibuffer Configuration integration
;; ==========================================

(defun ibuffer-advice (format)
  (ignore format)
  (with-current-buffer "*Ibuffer*"
    (save-excursion
      (let ((inhibit-read-only t))
        ;; Remove header and insert ours
        (goto-char (point-min))
        (search-forward "-\n" nil t)
        (delete-region 1 (point))
        (goto-char (point-min))
        (insert (concat
                 (propertize "\n" 'face '(:height 1.2))
                 (propertize " "  'display `(raise +0.25))
                 (propertize "  Buffers list (ibuffer)"
                             'face 'boba-faded)
                 (propertize " "  'display `(raise -0.35))
                 "\n"))
        (insert "")

        ;; Transform titles
        (goto-char (point-min))
        (while (re-search-forward "\\[ %s \\]" nil t)
          (let* ((title (match-string 0))
                 (property (get-text-property 0 'ibuffer-filter-group-name title)))
            (replace-match "\n")
            (insert (concat
                     (propertize
                      (format "   %s " (substring title 2 -2))
                      'ibuffer-filter-group-name property)
                     (propertize
                      (make-string (max 0 (- 30 (length title))) ?—)
                      'face 'boba-faded)
                     "\n"))))))))

(setq ibuffer-saved-filter-groups
       '(("home"
          ("Configuration" (or (filename . ".emacs.d")
                               (filename . "emacs-config")))
          ("Org" (or (mode . org-mode)
                     (filename . "OrgMode")))
          ("Code" (or  (derived-mode . prog-mode)
                       (mode . ess-mode)
                       (mode . compilation-mode)))
          ("Text" (and (derived-mode . text-mode)
                       (not  (starred-name))))
          ("TeX"  (or (derived-mode . tex-mode)
                      (is-derived-mode . latex-mode)
                      (mode . latex-mode)
                      (mode . context-mode)
                      (mode . ams-tex-mode)
                      (mode . bibtex-mode)))
          ("Help" (or (name . "\*Help\*")
                      (name . "\*Apropos\*")
                      (name . "\*info\*"))))))

(setq ibuffer-show-empty-filter-groups nil)
(setq ibuffer-display-summary nil)
(setq ibuffer-use-header-line nil)
(setq ibuffer-eliding-string (propertize "…" 'face 'boba-salient))
(setq ibuffer-fontification-alist '((0 t boba-salient)))
(setq ibuffer-formats
      '(("  "  mark " "(name 24 24 :left :elide) "  " modified)
        (mark " " (name 16 -1) " " filename)))

(defun ibuffer-setup ()
  (ibuffer-switch-to-saved-filter-groups "home")
  (ibuffer-auto-mode 1))

(defun boba-sidebar-init-ibuffer (frame sidebar)
  "Default sidebar initialization using ibuffer."
  (select-frame frame)
  (let ((buffer (current-buffer)))
    (ibuffer)
    (switch-to-buffer buffer))
  (select-frame sidebar)
  (switch-to-buffer "*Ibuffer*")
  (set-window-dedicated-p (get-buffer-window "*Ibuffer*") t)
  (hl-line-mode)
  (setq header-line-format nil)
  (setq mode-line-format nil))

(defun boba-sidebar-init-neotree (_frame sidebar)
  "Default sidebar initialization using neotree."
  (require 'neotree)
  (select-frame sidebar)
  (let ((neo-display-action '(display-buffer-same-window)))
    (neotree-show))
  (set-window-dedicated-p (selected-window) t)
  (hl-line-mode)
  (setq header-line-format nil)
  (setq mode-line-format nil))

;; ==========================================
;; Org Mode Sidebar Integration
;; ==========================================

(defun boba-sidebar-init-org-habits (_frame sidebar)
  "Sidebar initialization showing habits dashboard."
  (let* ((win (frame-selected-window sidebar))
         (buf (get-buffer-create "*Org Sidebar Habits*")))
    (set-window-dedicated-p win nil)
    (set-window-buffer win buf)
    (set-window-dedicated-p win t)
    (with-current-buffer buf
      (setq-local header-line-format nil)
      (setq-local mode-line-format nil)
      (hl-line-mode 1)
      (boba-sidebar-render-habits))))

(defun boba-sidebar-init-org-notes (_frame sidebar)
  "Sidebar initialization showing notes dashboard."
  (let* ((win (frame-selected-window sidebar))
         (buf (get-buffer-create "*Org Sidebar Notes*")))
    (set-window-dedicated-p win nil)
    (set-window-buffer win buf)
    (set-window-dedicated-p win t)
    (with-current-buffer buf
      (setq-local header-line-format nil)
      (setq-local mode-line-format nil)
      (hl-line-mode 1)
      (boba-sidebar-render-notes))))

(defun boba-sidebar-init-org-projects (_frame sidebar)
  "Sidebar initialization showing projects dashboard."
  (let* ((win (frame-selected-window sidebar))
         (buf (get-buffer-create "*Org Sidebar Projects*")))
    (set-window-dedicated-p win nil)
    (set-window-buffer win buf)
    (set-window-dedicated-p win t)
    (with-current-buffer buf
      (setq-local header-line-format nil)
      (setq-local mode-line-format nil)
      (hl-line-mode 1)
      (boba-sidebar-render-projects))))

(defun boba-sidebar-init-org-todo (_frame sidebar)
  "Sidebar initialization showing todo dashboard."
  (let* ((win (frame-selected-window sidebar))
         (buf (get-buffer-create "*Org Sidebar Todo*")))
    (set-window-dedicated-p win nil)
    (set-window-buffer win buf)
    (set-window-dedicated-p win t)
    (with-current-buffer buf
      (setq-local header-line-format nil)
      (setq-local mode-line-format nil)
      (hl-line-mode 1)
      (boba-sidebar-render-todo))))

(defun boba-sidebar-get-org-init-function (filename)
  "Return appropriate sidebar init function based on org filename."
  (cond
   ((string-match-p "habits\\.org$" filename) 'boba-sidebar-init-org-habits)
   ((string-match-p "notes\\.org$" filename) 'boba-sidebar-init-org-notes)
   ((string-match-p "projects\\.org$" filename) 'boba-sidebar-init-org-projects)
   ((string-match-p "todo\\.org$" filename) 'boba-sidebar-init-org-todo)
   ((and (boundp 'org-roam-directory)
         org-roam-directory
         (string-prefix-p (expand-file-name org-roam-directory)
                          (expand-file-name filename)))
    'boba-sidebar-init-org-roam)
   (t nil)))

(defun boba-sidebar-toggle-org ()
  "Toggle sidebar with org-specific content based on current buffer."
  (interactive)
  (let* ((filename (buffer-file-name))
         (org-init-func (cond
                         (filename (boba-sidebar-get-org-init-function filename))
                         ((or (derived-mode-p 'org-mode)
                              (string-equal (buffer-name) "*splash*")
                              (string-equal (buffer-name) "*scratch*"))
                          'boba-sidebar-init-org-roam)
                         (t nil)))
         (selected-frame (window-frame))
         (sidebar (frame-parameter nil 'sidebar))
         (sidebar-p (frame-parameter nil 'sidebar-p))
         (sidebar (if (frame-live-p sidebar) sidebar))
         (sidebar (if sidebar-p
                       (window-frame)
                     (or sidebar (boba-sidebar-create))))
         (parent (frame-parameter sidebar 'parent-frame))
         (sidebar-width (boba-sidebar-get-width parent))
         (visible (frame-parameter sidebar 'visibility)))

    (when visible
      (make-frame-invisible sidebar)
      (boba-sidebar-clear-margins parent))

    (when (not visible)
      ;; Set custom init function if we're in an org file
      (when org-init-func
        (set-frame-parameter parent 'sidebar-init org-init-func))
      
      (let* ((win (frame-selected-window parent))
             (hl-px  (or (window-header-line-height win) 0))
             (win-px (window-pixel-height win))
             ;; Sidebar spans full window height from top
             (sidebar-px-height win-px)
             (char-width (frame-char-width parent))
             (sidebar-px-width (* sidebar-width char-width))
             (parent-px-width (frame-pixel-width parent))
             (left-px (- parent-px-width sidebar-px-width)))
        (make-frame-visible sidebar)
        (modify-frame-parameters sidebar `((top    . 0)
                                           (height . ,win-px)
                                           (width  . ,sidebar-width)
                                           (left   . ,left-px)
                                           (pixelwise . t))))
      
      ;; Re-initialize sidebar with custom init if applicable
      (let ((init-func (boba-sidebar-get-init parent)))
        (when init-func
          (funcall init-func parent sidebar)))
      
      (boba-sidebar-push-margins parent sidebar-width)
      (select-frame-set-input-focus selected-frame))

    ;; Do not set frame-background-mode globally to avoid theme face resets
    ))

(defvar-local boba-sidebar-org-auto-opened nil
  "Track whether sidebar has been auto-opened for this org buffer.")

(defun boba-sidebar-org-auto-open ()
  "Auto-open sidebar with appropriate content for specific org files."
  (unless boba-sidebar--inhibit-update
    (let ((boba-sidebar--inhibit-update t))
      (when (and (derived-mode-p 'org-mode)
                 (not boba-sidebar-org-auto-opened)
                 (buffer-file-name))
        (let* ((filename (buffer-file-name))
               (org-init-func (boba-sidebar-get-org-init-function filename)))
          (when org-init-func
            (setq boba-sidebar-org-auto-opened t)
            (let* ((parent (window-frame))
                   (sidebar (frame-parameter parent 'sidebar))
                   (sidebar-width (boba-sidebar-get-width parent)))
              ;; If sidebar doesn't exist or is dead, create it
              (unless (and sidebar (frame-live-p sidebar))
                (setq sidebar (boba-sidebar-create)))
              ;; Set the init function and execute it
              (set-frame-parameter parent 'sidebar-init org-init-func)
              (funcall org-init-func parent sidebar)
              ;; Make sure frame parameters and visibility are set correctly
              (let* ((win (frame-selected-window parent))
                     (hl-px  (or (window-header-line-height win) 0))
                     (win-px (window-pixel-height win))
                     (sidebar-px-height (- win-px hl-px))
                     (char-width (frame-char-width parent))
                     (sidebar-px-width (* sidebar-width char-width))
                     (parent-px-width (frame-pixel-width parent))
                     (left-px (- parent-px-width sidebar-px-width)))
                (modify-frame-parameters sidebar `((top    . ,hl-px)
                                                   (height . ,sidebar-px-height)
                                                   (width  . ,sidebar-width)
                                                   (left   . ,left-px)
                                                   (pixelwise . t)))
                (make-frame-visible sidebar))
              ;; Push margins to prevent overlap!
              (boba-sidebar-push-margins parent sidebar-width)
              ;; Keep focus in parent frame!
              (select-frame-set-input-focus parent))))))))

(defvar boba-sidebar-last-global-buffer nil
  "Globally track the last active buffer for sidebar updates.")

(defun boba-sidebar-update-on-buffer-switch ()
  "Switch sidebar content dynamically when switching buffers."
  (unless boba-sidebar--inhibit-update
    (let ((current-buf (current-buffer)))
      (when (and (not (minibufferp))
                 (buffer-file-name current-buf)
                 (not (string-prefix-p " " (buffer-name current-buf)))
                 (not (eq current-buf boba-sidebar-last-global-buffer)))
        (setq boba-sidebar-last-global-buffer current-buf)
        (let* ((filename (buffer-file-name current-buf))
               (org-init-func (boba-sidebar-get-org-init-function filename)))
          (when org-init-func
            ;; If sidebar is visible, switch its content!
            (let* ((parent (window-frame))
                   (sidebar (frame-parameter parent 'sidebar)))
              (when (and sidebar (frame-live-p sidebar) (frame-parameter sidebar 'visibility))
                (let ((boba-sidebar--inhibit-update t))
                  (set-frame-parameter parent 'sidebar-init org-init-func)
                  (funcall org-init-func parent sidebar))))))))))

(defun boba-sidebar-after-save-hook ()
  "Refresh the sidebar dashboard if the saved file is one of our tracked org files."
  (when (and (derived-mode-p 'org-mode) (buffer-file-name))
    (let ((filename (buffer-file-name)))
      (cond
       ((string-match-p "habits\\.org$" filename) (boba-sidebar-render-habits))
       ((string-match-p "todo\\.org$" filename) (boba-sidebar-render-todo))
       ((string-match-p "projects\\.org$" filename) (boba-sidebar-render-projects))
       ((string-match-p "notes\\.org$" filename) (boba-sidebar-render-notes))
       ((and (boundp 'org-roam-directory)
             org-roam-directory
             (string-prefix-p (expand-file-name org-roam-directory)
                              (expand-file-name filename)))
        (boba-sidebar-render-roam))))))

(add-hook 'org-mode-hook #'boba-sidebar-org-auto-open)
(add-hook 'buffer-list-update-hook #'boba-sidebar-update-on-buffer-switch)
(add-hook 'post-command-hook #'boba-sidebar-update-on-buffer-switch)
(add-hook 'after-save-hook #'boba-sidebar-after-save-hook)

(advice-add 'ibuffer-update-title-and-summary :after #'ibuffer-advice)
(add-hook 'ibuffer-mode-hook #'ibuffer-setup)

(provide 'ui/sidebar)
(provide 'boba-sidebar)
;;; sidebar.el ends here
