;;; tools.el --- Nano tools module -*- lexical-binding: t; -*-

;; Copyright (C) 2024-2026 Nicolas P. Rougier, Atomic Emacs

;; Keywords: convenience

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;;; Commentary:
;; Combined Nano Tools module for Atomic Emacs containing:
;; - boba-box: One-pixel border around buffers using fringes, header/mode lines.
;; - boba-popup: Configurable popup windows.
;; - boba-journal: Small narrowed journal logging using org-datetree.
;; - boba-kill: Buffer and frame closing confirmation.
;; - boba-term: Toggle eat terminal at bottom.

;;; Code:

(require 'ui/modeline)
(require 'ui/read)
(require 'ui/faces)

(eval-when-compile
  (require 'org nil t)
  (require 'org-datetree nil t))

;; Forward declarations for byte-compiler
(defvar eat-buffer-name)
(defvar eat-exit-hook)
(defvar eat-mode-hook)
(defvar boba-modeline-format-terminal)
(declare-function eat-other-window "eat")
(declare-function boba-modeline "ui/modeline")

(defvar org-element-use-cache)
(defvar font-lock-extra-managed-props)
(declare-function org-with-wide-buffer "org-macs")
(declare-function org-datetree-find-date-create "org-datetree")
(declare-function org-narrow-to-subtree "org")
(declare-function org-current-level "org")
(declare-function org-get-heading "org")
(declare-function org-narrow-to-element "org")

;; =========================================================================
;; 1. NΛNO Box
;; =========================================================================

(defvar-local boba-box-cookies nil
  "Cookies to store local face modifications")

(defvar-local boba-box-state nil
  "State of the box around buffer")

(defvar-local boba-box-mode-line-format nil
  "Original mode-line format before turning box on")

(defvar-local boba-modeline-border-color nil
  "Local modeline border color")

;;;###autoload
(defun boba-box-on ()
  "Install a box around current buffer using fringes, header line and mode
line. This requires to have boba-modeline installed."
  (setq-local boba-box-mode-line-format mode-line-format)
  (setq boba-box-state t
        mode-line-format '(:eval (boba-modeline-element-window-spacing))
        overline-margin 0
        fringes-outside-margins t
        left-margin-width 1
        right-margin-width 1
        left-fringe-width 1
        right-fringe-width 1)
  (setq-local boba-modeline-border-color (face-foreground 'default))
  (mapc #'face-remap-remove-relative boba-box-cookies)
  (let ((color boba-modeline-border-color))
    (setq boba-box-cookies
          (list (face-remap-add-relative 'fringe
                                         `(:background ,color))
                (face-remap-add-relative 'header-line
                                         `(:box (:color ,(face-background 'default) :line-width (0 . 1))
                                                :underline nil :overline ,color))
                (face-remap-add-relative 'mode-line-active
                                         `(:overline ,color))
                (face-remap-add-relative 'mode-line-inactive
                                         `(:overline ,color)))))
  (set-window-margins nil 1 1)
  (when (eq (window-buffer) (current-buffer))
    (set-window-buffer nil (current-buffer))))

;;;###autoload
(defun boba-box-off ()
  "Remove borders from the current buffer."
  (setq-local boba-box-state nil
              left-fringe-width 1
              right-fringe-width 1
              left-margin-width 0
              right-margin-width 0
              mode-line-format boba-box-mode-line-format
              boba-modeline-border-color (face-background 'default))
  (mapc #'face-remap-remove-relative boba-box-cookies)
  (set-window-margins nil 0 0)
  (set-window-buffer nil (current-buffer)))

;;;###autoload
(defun boba-box ()
  "Toggle box depending on local state"
  (interactive)
  (if (not boba-box-state)
      (boba-box-on)
    (boba-box-off))
  (redisplay t))


;; =========================================================================
;; 2. NΛNO Popup
;; =========================================================================

;;;###autoload
(defun boba-popup (buffer)
  "Toggle a popup window at the bottom of frame displaying the given
BUFFER. The size of the window is saved such that toggling the window
does not change the window size."
  (interactive)
  (let ((window (get-buffer-window buffer)))
    (if window
        (progn
          (with-current-buffer buffer
            (setq-local window-height (window-height window)))
          (delete-window window))
      (progn
        (with-current-buffer buffer
          (pop-to-buffer buffer
                         `((display-buffer-at-bottom)
                           ,(when (boundp 'window-height)
                              (cons 'window-height window-height)))))
        (setq-local window-height (window-height (get-buffer-window buffer)))))))


;; =========================================================================
;; 3. NΛNO Journal
;; =========================================================================

(defcustom boba-journal-filename "~/Documents/org/journal.org"
  "Journal filename"
  :type 'file
  :group 'nano)

(defun boba-journal--last ()
  "Go to the last entry and update time if empty, else, create a new time entry."
  (interactive)
  (unless (featurep 'org)
    (require 'org))
  (unless (featurep 'org-datetree)
    (require 'org-datetree))
  (let ((day   (nth 3 (decode-time (current-time))))
        (month (nth 4 (decode-time (current-time))))
        (year  (nth 5 (decode-time (current-time)))))
    (org-with-wide-buffer
     (org-datetree-find-date-create (list month day year))
     (org-narrow-to-subtree))
    (goto-char (point-max))
    (cond ((search-backward (format-time-string "%H:%M") nil t)
           (end-of-line))
          ((search-backward-regexp "[0-9][0-9]:[0-9][0-9] \n" nil t)
           (with-silent-modifications
             (replace-match (format-time-string "%H:%M \n")))
           (backward-char))
          (t
           (goto-char (point-max))
           (with-silent-modifications
             (insert (format-time-string "\n%H:%M \n")))
           (backward-char)))
    (org-narrow-to-element)))

(defun boba-journal--heading ()
  "Return a string describing the current heading (that is supposed to be a date)."
  (unless (featurep 'org)
    (require 'org))
  (let* ((heading (or (org-with-wide-buffer (org-get-heading)) ""))
         (date (if (eq (org-current-level) 3)
                   (let ((date (date-to-time heading)))
                     (format-time-string "%A, %d %B %Y" date))
                 heading)))
    (propertize (format "%s" date)
                'face 'boba-modeline-face-default)))

(defun boba-journal--setup ()
  "Setup the journal buffer with dedicated font-lock, modeline and a box around it."
  (let ((buffer (pop-to-buffer (find-file-noselect boba-journal-filename)
                               '((display-buffer-at-bottom)
                                 (window-height . 12)
                                 (dedicated . t)))))
    (with-current-buffer buffer
      (push 'display font-lock-extra-managed-props)
      (font-lock-add-keywords nil
                              `("\\([0-9][0-9]:[0-9][0-9]\\)" 1 '(boba-strong) prepend)
                              `("\\(#[A-Za-z0-9]+\\)"         1 '(boba-popout boba-strong) prepend))
      (font-lock-flush (point-min) (point-max))
      (boba-box-on)
      (setq-local org-element-use-cache nil)
      (boba-modeline (cons '((boba-modeline-element-buffer-status "LOG")
                             boba-modeline-element-space
                             boba-journal--heading
                             boba-modeline-element-space
                             boba-modeline-element-buffer-vc-mode)
                           '(boba-modeline-element-window-status
                             boba-modeline-element-space)))
      (boba-journal--last))))

;;;###autoload
(defun boba-journal ()
  "Show/hide journal and narrow to last entry."
  (interactive)
  (if (get-file-buffer boba-journal-filename)
      (let ((buffer (get-file-buffer boba-journal-filename)))
        (boba-popup (get-file-buffer boba-journal-filename))
        (when (get-buffer-window buffer)
          (with-current-buffer buffer
            (boba-journal--last))))
    (boba-journal--setup)))


;; =========================================================================
;; 4. NΛNO Kill
;; =========================================================================

;;;###autoload
(defun boba-kill-emacs ()
  "Close frame or kill emacs if current frame is the last one."
  (interactive)
  (if (> (length (frame-list)) 1)
      (progn (delete-frame))
    (if (files--buffers-needing-to-be-saved nil)
        (let ((answer
               (boba-read-yes-or-no
                (propertize "WARNING" 'face 'boba-critical-i)
                (propertize "Some buffers are modified. What do you want to do?"
                            'face 'boba-default)
                (list (propertize "Cancel" 'face 'boba-default)
                      (concat (propertize "Save & " 'face 'boba-default)
                              (propertize "Quit" 'face 'boba-critical))
                      (propertize "Quit" 'face 'boba-critical)))))
          (cond ((equal answer "Save & Quit")
                 (save-buffers-kill-terminal t))
                ((equal answer "Quit")
                 (kill-emacs))))
      (kill-emacs))))

;;;###autoload
(defun boba-kill-buffer ()
  "Kill buffer and ask for confirmation if modified."
  (interactive)
  (if (and (buffer-modified-p)
           (not (equal (buffer-name) " *Compiler Input*"))
           (not (derived-mode-p '(special-mode
                                  help-mode
                                  elisp-compile-mode
                                  compilation-mode)))
           (or (derived-mode-p '(prog-mode text-mode))))
      (let ((answer
             (boba-read-yes-or-no
              (propertize "WARNING" 'face 'boba-critical-i)
              (concat "Buffer "
                      (propertize (buffer-name) 'face 'bold)
                      " has been modified, kill it anyway?")
              (list (propertize "NO" 'face 'boba-default)
                    (propertize "YES" 'face 'boba-critical)))))
        (if (equal answer "YES")
            (progn
              (set-buffer-modified-p nil)
              (kill-buffer (current-buffer)))
          (message "Buffer kill cancelled")))
    (kill-buffer (current-buffer))))


;; =========================================================================
;; 5. NΛNO Term
;; =========================================================================

(with-eval-after-load 'eat
  (add-hook 'eat-exit-hook (lambda (_process)
                             (when (get-buffer eat-buffer-name)
                               (kill-buffer eat-buffer-name))))
  (add-hook 'eat-mode-hook (lambda ()
                             (boba-modeline boba-modeline-format-terminal)
                             (face-remap-add-relative 'header-line `(:background ,theme-color-subtle))
                             (face-remap-add-relative 'region `(:background ,theme-color-subtle))
                             (face-remap-add-relative 'default `(:background ,theme-color-background)))))

;;;###autoload
(defun boba-term ()
  "Show/hide eat terminal at the bottom of the frame."
  (interactive)
  (unless (featurep 'eat)
    (require 'eat nil t))
  (if (not (featurep 'eat))
      (error "Eat package is not available. Please install it first")
    (if (get-buffer eat-buffer-name)
        (boba-popup eat-buffer-name)
      (let ((display-buffer-alist `(("\\*eat\\*"
                                     (display-buffer-at-bottom)
                                     (window-height . 12)
                                     (dedicated . t)))))
        (eat-other-window)
        (with-current-buffer eat-buffer-name
          (boba-box-on))))))

(provide 'ui/tools)
(provide 'boba-box)
(provide 'boba-popup)
(provide 'boba-journal)
(provide 'boba-kill)
(provide 'boba-term)
;;; tools.el ends here
