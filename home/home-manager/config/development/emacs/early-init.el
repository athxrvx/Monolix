;;; early-init.el --- Early initialization and optimizations for Atomic Emacs -*- lexical-binding: t; -*-

;; Optimize garbage collection thresholds during startup.
;; Doom Emacs uses 16MB or more, we use 64MB for a fast load.
(setq gc-cons-threshold 67108864 ; 64MB
      gc-cons-percentage 0.6)

;; Temporarily disable file-name-handler-alist to speed up loading elisp files.
(defvar my-saved-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Restore GC and file-name-handler-alist after startup.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 8388608 ; 8MB
                  gc-cons-percentage 0.1
                  file-name-handler-alist my-saved-file-name-handler-alist)
            ;; Clean up memory right after init finishes.
            (garbage-collect)))

;; Prevent package.el from loading packages automatically at startup.
;; We are using straight.el, so package.el is not needed.
(setq package-enable-at-startup nil)

;; Avoid resizing the frame when loading fonts or themes (improves startup speed).
(setq frame-inhibit-implied-resize t)

;; Disable GUI decorations early to prevent a visual flash during startup.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil
      tooltip-mode nil)

;; Inhibit startup messages and splash screens.
(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      initial-scratch-message nil)

(provide 'early-init)
;;; early-init.el ends here
