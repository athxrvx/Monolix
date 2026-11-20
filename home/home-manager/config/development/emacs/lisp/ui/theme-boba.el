;;; theme-boba.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'ui/base-colors)

(defun theme-set-boba ()
  "Apply Boba theme (warm literary light theme) base."
  (setq frame-background-mode    'light)
  (setq theme-color-foreground   "#605A52") ;; Tapioca
  (setq theme-color-background   "#FCFBF9") ;; Milk Tea
  (setq theme-color-highlight    "#F5F1EC") ;; Current/hl-line
  (setq theme-color-critical     "#8F5652") ;; Rose Tea / Red
  (setq theme-color-salient      "#83577D") ;; Taro / Purple
  (setq theme-color-strong       "#4A443C") ;; Dark Tapioca
  (setq theme-color-popout       "#886A44") ;; Brown Sugar / Orange
  (setq theme-color-subtle       "#F7F3EE") ;; Foam / bg-alt
  (setq theme-color-faded        "#938A80") ;; Comment (slightly darker for contrast)
  (setq theme-color-modeline-bg  "#F7F3EE") ;; Foam / bg-alt
  (setq theme-var "boba")
  )

(provide 'ui/theme-boba)
