;;; windows.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Window Setup
(use-package window
  :ensure nil
  :custom
  ;; Emacs often opens buffers in new windows. Make window splitting and
  ;; placement more predictable.
  ;; TODO: revisit this setting?
  (display-buffer-base-action nil)
  ;; NOTE: I found the below unhelpful, but not sure what better settings would
  ;; be.
  ;; '((display-buffer-use-least-recent-window
  ;; display-buffer--maybe-pop-up-frame-or-window display-buffer-reuse-window
  ;; display-buffer-reuse-mode-window display-buffer-same-window
  ;; display-buffer-in-previous-window display-buffer-pop-up-frame)))
  )

;;;; Window Division
;; Vertical window divider
(use-package frame
  :ensure nil
  :custom
  (window-divider-default-right-width 10)
  (window-divider-default-bottom-width 10)
  (window-divider-default-places 'right-only)
  (window-divider-mode t))
;; Make sure new frames use window-divider
(add-hook 'before-make-frame-hook 'window-divider-mode)

;;;;; Window Movement
;;FIXME: Figure out how best to streamline window movement.
;; Quickly switch windows in Emacs
(use-package ace-window
  :when (and lem-load-extras (locate-library "ace-window"))
  :commands (ace-window
             ace-swap-window
             aw-flip-window))

(defun lem-other-window ()
  (interactive)
  (other-window 1))
(bind-key* "C-c C-o" 'lem-other-window)


;; Easy window movement by key
(use-package windmove
  :ensure nil
  :commands (windmove-up
             windmove-down
             windmove-left
             windmove-right)
  :bind (("C-c C-h" . #'windmove-left)
         ("C-c C-l" . #'windmove-right)
         ("C-c C-j" . #'windmove-down)
         ("C-c C-k" . #'windmove-up))
  :config
  (windmove-default-keybindings))

;;;;; Window Restore
;; Winner mode is a built-in package for restoring window configurations
;; https://www.emacswiki.org/emacs/WinnerMode
(use-package winner
  :ensure nil
  :hook (after-init . winner-mode))


(provide 'component/windows)
;;; lem-setup-windows.el ends here
