;;; core.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(package-initialize)

;; Add the path of the file being evaluated to `load-path'.
(when (and (boundp 'load-path) load-file-name)
  (add-to-list 'load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Default layout (optional)
(require 'boba-layout)

;; Theming Command line options (this will cancel warning messages)
(add-to-list 'command-switch-alist '("-dark"   . (lambda (args))))
(add-to-list 'command-switch-alist '("-light"  . (lambda (args))))
(add-to-list 'command-switch-alist '("-default"  . (lambda (args))))
(add-to-list 'command-switch-alist '("-no-splash" . (lambda (args))))
(add-to-list 'command-switch-alist '("-no-help" . (lambda (args))))
(add-to-list 'command-switch-alist '("-compact" . (lambda (args))))


;; Customize support for 'emacs -q' (Optional)
;; You can enable customizations by creating the boba-custom.el file
;; with e.g. `touch boba-custom.el` in the folder containing this file.
(let* ((this-file  (or load-file-name (buffer-file-name)))
       (this-dir  (file-name-directory this-file))
       (custom-path  (concat this-dir "boba-custom.el")))
  (when (and (eq nil user-init-file)
             (eq nil custom-file)
             (file-exists-p custom-path))
    (setq user-init-file this-file)
    (setq custom-file custom-path)
    (load custom-file)))

;; Theme
(require 'theme-faces)
(require 'theme-apply)
(require 'theme-apply-dark)
(require 'theme-apply-light)

(cond
 ((member "-default" command-line-args) t)
 ((member "-dark" command-line-args) (theme-set-dark))
 (t (theme-set-boba)))
(call-interactively 'theme-refresh)

;; Nano default settings (optional)
(require 'boba-defaults)

;; Nano session saving (optional)
(require 'boba-session)

;; Nano header & mode lines (optional)
(require 'modeline)

;; Nano key bindings modification (optional)
(require 'boba-bindings)

;; Compact layout (need to be loaded after modeline)
(when (member "-compact" command-line-args)
  (require 'boba-compact))

;; Nano counsel configuration (optional)
;; Needs "counsel" package to be installed (M-x: package-install)
;; (require 'counsel)

;; Welcome message (optional)
(let ((inhibit-message t))
  (message "Welcome to GNU Emacs / N Λ N O edition")
  (message (format "Initialization time: %s" (emacs-init-time))))

;; Splash (optional)
(unless (member "-no-splash" command-line-args)
  (require 'dashboard-splash))

;; Help (optional)
(unless (member "-no-help" command-line-args)
  (require 'boba-help))

(provide 'nano)
