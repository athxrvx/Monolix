;;; colors.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Color
(setq-default ns-use-srgb-colorspace t)

;;;; Show Colors
;; https://github.com/emacsmirror/rainbow-mode
;; Colorize color names in buffers
(use-package rainbow-mode
  :when (and lem-load-extras (locate-library "rainbow-mode"))
  :commands rainbow-mode)

(provide 'component/colors)
;;; lem-setup-colors.el ends here
