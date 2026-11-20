;;; minibuffer.el --- NΛNO Minibuffer module -*- lexical-binding: t -*-

;; Copyright (C) 2022-2026 Nicolas P. Rougier, Atomic Emacs

;; Maintainer: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; URL: https://github.com/rougier/boba-minibuffer
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (mini-frame))
;; Keywords: convenience

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;;; Commentary:
;; Configures muffinmad's `mini-frame` to display the minibuffer in an
;; auto-sizing child frame with a custom header. Fully integrated
;; with Atomic Emacs theme refresh.

;;; Code:

(require 'mini-frame)
(require 'ui/faces)
(require 'ui/theme)

;; Forward declarations for byte-compiler
(defvar mini-frame-default-height)
(defvar ivy-height)
(defvar ivy-format-functions-alist)
(declare-function ivy-format-function-line "ivy")

(defgroup boba-minibuffer nil
  "NΛNO Minibuffer settings"
  :group 'nano)

(defcustom boba-minibuffer-position 'bottom
  "Minibuffer position, one of \\='top or \\='bottom."
  :type '(choice (const :tag "Top"    top)
                 (const :tag "Bottom" bottom))
  :group 'boba-minibuffer)

(defface boba-minibuffer-face nil
  "Face for the minibuffer."
  :group 'boba-minibuffer)

(defface boba-minibuffer-header-face nil
  "Face for the minibuffer header."
  :group 'boba-minibuffer)

(defun boba-minibuffer-header ()
  "Header line function for the minibuffer"
  (let* ((depth (minibuffer-depth))
         (left (concat " ☰ "
                       (if (> depth 1)
                           (format "Minibuffer (%d)" depth)
                         "Minibuffer")))
         (right "C-g: abort")
         (spacer (propertize " " 
                             'display `(space :align-to (- right
                                                           (-1 . right-margin)
                                                           ,(- (length right) -1))))))
    (concat left spacer right "\n")))

(defun boba-minibuffer-setup ()
  "Install a header line in the minibuffer via an overlay (and a hook)"
  (set-window-margins nil 0 0)
  (set-fringe-style '(0 . 0))
  (cursor-intangible-mode t)
  (local-set-key (kbd "<escape>") #'abort-minibuffers)
  (face-remap-add-relative 'default :inherit 'boba-minibuffer-face)
  (let* ((_overlay (make-overlay (+ (point-min) 0) (+ (point-min) 0)))
         (inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (insert (propertize
               (concat (propertize (boba-minibuffer-header)
                                   'face 'boba-minibuffer-header-face)
                       (propertize "\n" 'face `(:height 0.33))
                       (propertize " "))
               'cursor-intangible t
               'read-only t
               'field t
               'rear-nonsticky t
               'front-sticky t)))))

(defun boba-minibuffer--frame-parameters ()
  "Compute minibuffer frame size and position."
  (let* ((edges (window-pixel-edges)) ;; (left top right bottom)
         (left (nth 0 edges)) ;; Take margins into account
         (top (nth 1 edges)) ;; Drop header line
         (left (if (eq left-fringe-width 0)
                   left
                 (- left (frame-parameter nil 'left-fringe))))
         (right (nth 2 edges))
         (right (if (eq right-fringe-width 0)
                    right
                  (+ right (frame-parameter nil 'right-fringe))))
         (border 1)
         (width (- right left (* 0 border)))

         ;; Window divider mode
         (width (- width (if (and (bound-and-true-p window-divider-mode)
                                  (or (eq window-divider-default-places 'right-only)
                                      (eq window-divider-default-places t))
                                  (window-in-direction 'right (selected-window)))
                             window-divider-default-right-width
                           0)))
         (y (- top border)))

    (append `((left-fringe . 0)
              (right-fringe . 0)
              (user-position . t) 
              (foreground-color . ,(face-foreground 'boba-minibuffer-face nil 'default))
              (background-color . ,(face-background 'boba-minibuffer-face nil 'default)))
            (cond ((eq boba-minibuffer-position 'bottom)
                   `((top . -1)
                     (left . 0)
                     (width . 1.0)
                     (child-frame-border-width . 0)
                     (internal-border-width . 0)))
                  (t
                   `((left . ,(- left border))
                     (top . ,y)
                     (width . (text-pixels . ,width))
                     (child-frame-border-width . ,border)
                     (internal-border-width . ,border)))))))

(defun boba-minibuffer-mode--activate ()
  "Activate boba-minibuffer minor mode"
  (my-update-minibuffer-colors)
  (setq mini-frame-default-height 6)
  (setq mini-frame-create-lazy t)
  (setq mini-frame-show-parameters 'boba-minibuffer--frame-parameters)
  (setq mini-frame-ignore-commands
        '("edebug-eval-expression" debugger-eval-expression))
  (setq mini-frame-resize-min-height 6)
  (customize-set-variable 'mini-frame-resize t)
  (add-hook 'minibuffer-setup-hook #'boba-minibuffer-setup)
  (mini-frame-mode 1))

(defun boba-minibuffer-mode--inactivate ()
  "Deactivate boba-minibuffer minor mode"
  (remove-hook 'minibuffer-setup-hook #'boba-minibuffer-setup)
  (mini-frame-mode -1))

;;;###autoload
(define-minor-mode boba-minibuffer-mode
  "Toggle boba-minibuffer minor mode"
  :group 'boba-minibuffer
  :global t
  :init-value nil

  (if boba-minibuffer-mode
      (boba-minibuffer-mode--activate)
    (boba-minibuffer-mode--inactivate))

  (run-hooks 'boba-minibuffer-mode-hook))

;; =========================================================================
;; Ivy / Swiper styling preservation
;; =========================================================================

(with-eval-after-load 'ivy
  (setq ivy-height 4)
  (set-face 'ivy-current-match 'theme-face-strong)
  (setcdr (assoc t ivy-format-functions-alist) #'ivy-format-function-line)
  (set-face-attribute 'ivy-current-match nil
                      :extend t
                      :foreground theme-color-background
                      :background theme-color-faded))

;; =========================================================================
;; Dynamic Theme Support
;; =========================================================================

(defun my-update-minibuffer-colors ()
  "Update custom boba-minibuffer settings dynamically based on theme."
  (interactive)
  (set-face-attribute 'boba-minibuffer-face nil
                      :inherit 'default)
  (set-face-attribute 'boba-minibuffer-header-face nil
                      :inherit 'theme-face-header-default)
  (when (facep 'child-frame-border)
    (set-face-background 'child-frame-border (face-foreground 'boba-faded nil t)))
  (setq mini-frame-internal-border-color (face-foreground 'boba-faded nil t)))

(with-eval-after-load 'ui/theme
  (advice-add 'theme-refresh :after #'my-update-minibuffer-colors))

;; Initialize colors
(my-update-minibuffer-colors)

;; Activate minibuffer mode by default (disabled for now)
;; (boba-minibuffer-mode 1)

(provide 'ui/minibuffer)
(provide 'boba-minibuffer)
;;; minibuffer.el ends here
