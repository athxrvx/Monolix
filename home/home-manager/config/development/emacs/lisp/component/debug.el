;;; debug.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Bug Hunter
(use-package bug-hunter
  :when (and lem-load-extras (locate-library "bug-hunter"))
  :defer 2)

;;;; Emacs Profiling
;; might be worth checking this out more closely
;; https://github.com/raxod502/radian/blob/c4246176155873d3937ff997965279048dabbc01/emacs/radian.el#L4423-L4476
;; Use fork of esup (original is unmaintained)
(use-package esup
  :when (and lem-load-extras (locate-library "esup"))
  :ensure nil
  :init
  (unless (package-installed-p 'esup)
    (package-vc-install "https://github.com/kiennq/esup.git"))
  :commands esup)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'component/debug)
;;; setup-debug.el ends here
