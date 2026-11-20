;;; toolbar.el --- Toolbar in the header line -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Nicolas P. Rougier

;; Maintainer: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; URL: https://github.com/rougier/boba-toolbar
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1" svg-lib))
;; Keywords: widgets, header-line

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides a NΛNO toolbar in the header line using svg-lib tags.
;;

;;; Code:
(require 'svg-lib nil t)   ; soft require — no error if not yet loaded
(require 'color)

(defgroup boba-toolbar nil
  "N Λ N O Toolbar"
  :group 'nano)

(defcustom boba-toolbar-prompt-face 'theme-face-strong
  "Face for the prompt"
  :group 'boba-toolbar
  :type 'face)

(defcustom boba-toolbar-button-faces
  '((disabled . theme-face-faded)
    (default  . theme-face-default)
    (hover    . theme-face-subtle)
    (active   . theme-face-strong))
  "Faces for the four possible button states"
  :group 'boba-toolbar
  :type '(list (cons (const :tag "Disabled" disabled) face)
               (cons (const :tag "Default"  default) face)
               (cons (const :tag "Hover"    hover) face)
               (cons (const :tag "Active"   active) face)))

(defcustom boba-toolbar-space-top 0.20
  "Top spacing (purely aesthetic)"
  :group 'boba-toolbar
  :type 'float)
  
(defcustom boba-toolbar-space-bottom 0.25
  "Bottom spacing (purely aesthetic)"
  :group 'boba-toolbar
  :type 'float)

(defvar boba-toolbar--buttons nil
  "List of buttons as a cons cell (LABEL . STATE)")

(defvar boba-toolbar--index-current 0
  "Index of the current selected button")

(defvar boba-toolbar--index-pointer nil
  "Index of the current mouse selected button")

(defvar boba-toolbar--index-mouse nil)

(defun boba-toolbar--make-button (button)
  "Create a BUTTON with given label and state and install mouse handlers."
  (let* ((label (car button))
         (state (cdr button))
         (face (cdr (assoc state boba-toolbar-button-faces)))
         (dark (color-dark-p (color-name-to-rgb (face-background face nil 'default))))
         (stroke (if dark 0 2))
         (weight (if dark 'semibold 'light))
         (foreground (face-foreground face nil 'default))
         (background (face-background face nil 'default)))
    (propertize label
                'pointer 'hand
                'help-echo `(lambda (window object pos)
                              (boba-toolbar--highlight-button ,label))
                'keymap (let ((map (make-sparse-keymap)))
                          (define-key map [header-line mouse-1]
                            `(lambda () (interactive) (boba-toolbar--activate-button ,label)))
                          map)
                'display (svg-lib-tag label nil :stroke stroke
                                                :font-weight weight
                                                :foreground foreground
                                                :background background))))

(defun boba-toolbar--highlight-button (label)
  "Change button LABEL to highlight state."
  (setq boba-toolbar--index-pointer nil)
  (let ((index 0))
    (dolist (button boba-toolbar--buttons)
      (when (not (equal (cdr button) 'active))
        (if (equal (car button) label)
            (progn
              (setcdr button 'hover)
              (setq boba-toolbar--index-pointer index))
          (setcdr button 'default)))
      (setq index (+ index 1))))
  (force-mode-line-update))

(defun boba-toolbar--activate-button (label)
  "Change button LABEL to activated state."
  (dolist (button boba-toolbar--buttons)
    (if (equal (car button) label)
        (setcdr button 'active)
      (setcdr button 'default)))
  (force-mode-line-update))

(defun boba-toolbar--mouse-activate ()
  "Activate current mouse selection."
  (interactive)
  (when boba-toolbar--index-pointer
    (setq boba-toolbar--index-current boba-toolbar--index-pointer)
    (let ((label (car (nth boba-toolbar--index-current boba-toolbar--buttons))))
      (boba-toolbar--activate-button label))
    (setq boba-toolbar--index-pointer nil)
    (throw 'break nil)))

(defun boba-toolbar--activate-next ()
  "Activate next button"
  (interactive)
  (setq boba-toolbar--index-current (mod (+ boba-toolbar--index-current 1) (length boba-toolbar--buttons)))
  (let ((label (car (nth boba-toolbar--index-current boba-toolbar--buttons))))
    (boba-toolbar--activate-button label)))

(defun boba-toolbar--activate-prev ()
  "Activate previous button"
  (interactive)
  (setq boba-toolbar--index-current (mod (- boba-toolbar--index-current 1) (length boba-toolbar--buttons)))
  (let ((label (car (nth boba-toolbar--index-current boba-toolbar--buttons))))
    (boba-toolbar--activate-button label)))

(defun boba-toolbar--select ()
  "Select current button"
  (interactive)
  (let ((label (car (nth boba-toolbar--index-current boba-toolbar--buttons))))
    (boba-toolbar--activate-button label)))

(defun boba-toolbar--cancel ()
  "Cancel toolbar"
  (throw 'break nil))

(defun boba-toolbar--validate ()
  "Validate current button"
  (throw 'break nil))

(defun boba-toolbar (prompt buttons)
  "Create a toolbar in the header line using given PROMPT and BUTTONS description"
  (setq boba-toolbar--buttons buttons)
  (setq boba-toolbar--index-mouse nil)
  (let ((saved-header-line-format header-line-format))
    ;; We use tooltip mode to highlight button under mouse cursor
    (tooltip-mode t)
    (setq tooltip-delay 0.0)
    (advice-add 'tooltip-hide :before
                (lambda (&optional args)
                  (ignore args)
                  (boba-toolbar--highlight-button "")))

    ;; Install toolbar 
    (setq-local header-line-format
              `(:eval
                (concat
                 (propertize ,prompt 'face boba-toolbar-prompt-face
                             'display `(raise 0.1))
                 (if (> (length ,prompt) 0) " " "")
                 (mapconcat (lambda (button) (boba-toolbar--make-button button)) boba-toolbar--buttons " ")
                 (propertize " " 'face `(:underline ,(face-background 'default))
                                 'display `(raise ,boba-toolbar-space-top))
                 (propertize " " 'face `(:underline ,(face-background 'default))
                             'display `(raise ,(- boba-toolbar-space-bottom))))))

    ;; Process keyboard and mouse events (blocking)
    (catch 'break
      (while t
        (let* ((event (read-key-sequence nil))
               (key (key-description event)))
          (cond ((string= key "C-g")     (boba-toolbar--cancel))
                ((string= key "RET")     (boba-toolbar--validate))
                ((string= key "SPC")     (boba-toolbar--select))
                ((string= "<header-line> <mouse-1>" (boba-toolbar--mouse-activate)))
                ((string= key "<right>") (boba-toolbar--activate-next))
                ((string= key "<left>")  (boba-toolbar--activate-prev))))))

    ;; Restore header-line
    (setq-local header-line-format saved-header-line-format)

    ;; Read selection
    (catch 'break
      (dolist (button boba-toolbar--buttons)
        (if (equal (cdr button) 'active)
            (throw 'break (car button)))))))

(provide 'ui/toolbar)
(provide 'boba-toolbar)
;;; toolbar.el ends here
