;;; icons.el --- Nerd icons integration -*- lexical-binding: t; -*-

(use-package nerd-icons
  :demand t
  :custom
  (nerd-icons-font-family "JetBrainsMono Nerd Font"))

(use-package nerd-icons-completion
  :demand t
  :after (marginalia nerd-icons)
  :hook
  (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :config
  (nerd-icons-completion-mode 1)
  (when (bound-and-true-p marginalia-mode)
    (nerd-icons-completion-marginalia-setup)))

(use-package nerd-icons-dired
  :after (dired nerd-icons)
  :hook
  (dired-mode . nerd-icons-dired-mode))

(use-package svg-icon
  :straight (emacs-svg-icon :type git :host github :repo "rougier/emacs-svg-icon")
  :commands svg-icon
  :custom
  (svg-icon-collections
   '(("bootstrap" . "https://icons.getbootstrap.com/icons/%s.svg")
     ("material"  . "https://raw.githubusercontent.com/Templarian/MaterialDesign/master/svg/%s.svg")
     ("octicons"  . "https://raw.githubusercontent.com/primer/octicons/master/icons/%s-24.svg")
     ("boxicons"  . "https://raw.githubusercontent.com/atisawd/boxicons/master/svg/regular/bx-%s.svg")
     ("boxicons-solid" . "https://raw.githubusercontent.com/atisawd/boxicons/master/svg/solid/bxs-%s.svg"))))

(with-eval-after-load 'url-cache
  (defun svg-icon-ensure-cache-dir (filename)
    "Ensure parent directory of FILENAME exists."
    (when filename
      (make-directory (file-name-directory filename) t))
    filename)
  (advice-add 'url-cache-create-filename :filter-return #'svg-icon-ensure-cache-dir))

(provide 'ui/icons)
;;; icons.el ends here
