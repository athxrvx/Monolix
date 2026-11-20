;;; libraries.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;; Built in libraries; lots of packages depend on these
(use-package subr-x
  :ensure nil
  :defer 1)
(use-package cl-lib
  :ensure nil
  :defer t)
;; Include this only for compatibility purposes
(use-package cl
  :ensure nil
  :defer t)

;; Asynchronous commands. Adds the ability to call asynchronous functions and
;; process with ease. See the documentation for `async-start' and
;; `async-start-process'.
(use-package async
  :when (and lem-load-extras (locate-library "async"))
  :defer
  :config
  (dired-async-mode 1)
  (setq dired-async--modeline-mode nil))

;; A modern list API for Emacs. No 'cl required.
(use-package dash
  :when (and lem-load-extras (locate-library "dash"))
  :defer 2)
;; String manipulation
(use-package s
  :when (and lem-load-extras (locate-library "s"))
  :defer 2)
;; APIs for files & directories
(use-package f
  :when (and lem-load-extras (locate-library "f"))
  :defer 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'component/libraries)
;;; lem-setup-libraries.el ends here
