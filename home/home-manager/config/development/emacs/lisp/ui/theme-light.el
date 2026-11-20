;;; theme-light.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'ui/base-colors)
(defun theme-set-light ()
  "Apply light Nano theme base."
  ;; Colors from Material design at https://material.io/
  (setq frame-background-mode    'light)
  (setq theme-color-foreground "#37474F") ;; Blue Grey / L800
  (setq theme-color-background "#FFFFFF") ;; White
  (setq theme-color-highlight  "#FAFAFA") ;; Very Light Grey
  (setq theme-color-critical   "#FF6F00") ;; Amber / L900
  (setq theme-color-salient    "#2B6CB0") ;; Slate Blue / L500
  (setq theme-color-strong     "#000000") ;; Black
  (setq theme-color-popout     "#FFAB91") ;; Deep Orange / L200
  (setq theme-color-subtle     "#ECEFF1") ;; Blue Grey / L50
  (setq theme-color-faded      "#B0BEC5") ;; Blue Grey / L200
  (setq theme-color-modeline-bg "#ECEFF1")
  ;; to allow for toggling of the themes.
  (setq theme-var "light")
  )

(provide 'ui/theme-light)
