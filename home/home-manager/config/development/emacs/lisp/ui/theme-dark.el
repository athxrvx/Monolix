;;; theme-dark.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'ui/base-colors)

(defun theme-set-dark ()
  "Apply dark theme based on Tomorrow-Night, Jellybeans, and Bikkuri."
  (setq frame-background-mode     'dark)
  (setq theme-color-foreground   "#dcd6c5") ;; Soft tapioca cream/white
  (setq theme-color-background   "#1b1816") ;; Bikkuri Dark Warm base (deep warm chocolate)
  (setq theme-color-highlight    "#24201e") ;; Warm current line
  (setq theme-color-critical     "#cf6a4c") ;; Jellybeans Rust Red
  (setq theme-color-salient      "#8197bf") ;; Jellybeans Slate Blue
  (setq theme-color-strong       "#f4efe4") ;; Warm tapioca bright white
  (setq theme-color-popout       "#de935f") ;; Tomorrow Night Orange
  (setq theme-color-subtle       "#231f1d") ;; Warm tea accent
  (setq theme-color-faded        "#938a80") ;; Warm faded grey comment
  (setq theme-color-modeline-bg  "#231f1d") ;; Modeline Background
  (setq theme-var "dark")
  )

(provide 'ui/theme-dark)
