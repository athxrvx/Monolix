;;; init.el --- Bobamacs main entry point -*- lexical-binding: t; -*-

;; Bobamacs framework paths
(defvar boba-config-dir (expand-file-name "boba" (or (getenv "XDG_CONFIG_HOME") "~/.config"))
  "User configuration directory (~/.config/boba).")
(defvar boba-data-dir (expand-file-name "boba" (or (getenv "XDG_DATA_HOME") "~/.local/share"))
  "Data directory (~/.local/share/boba).")

;; Ensure directories exist
(dolist (dir (list boba-config-dir boba-data-dir))
  (unless (file-directory-p dir)
    (make-directory dir t)))

;; Load user configuration before package bootstrap
(defvar boba-user-config-file (expand-file-name "config.el" boba-config-dir))
(when (file-exists-p boba-user-config-file)
  (load boba-user-config-file 'noerror))

;; ==========================================
;; 1. Bootstrap straight.el Package Manager
;; ==========================================

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        user-emacs-directory))
      (bootstrap-var-occurs
       (and (boundp 'bootstrap-version)
            bootstrap-version)))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-min))
      (re-search-forward "^$" nil t)
      (eval-region (point) (point-max))))
  (load bootstrap-file nil 'nomessage))

;; Integrate straight.el with use-package
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(straight-use-package '(org :type built-in))

;; ==========================================
;; 2. Add Integrated Modules to Load Path
;; ==========================================

;; Add the unified lisp folder to load-path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; ==========================================
;; 3. Load Modular Configuration
;; ==========================================

(require 'ui/theme)
(require 'ui/dashboard)
(require 'require-all-ui-modules)
(require 'ui/modeline)
(require 'syntax/editing)
(require 'navigation/completion)
(require 'navigation/projects)
(require 'navigation/evil)
(require 'code/lsp)
(require 'syntax/org)
(require 'syntax/org-roam)
(require 'component/nerdtree)
(require 'ui/diff-hl)
(require 'ui/icons)
(require 'ui/indent-guides)
(require 'syntax/rainbow-delimiters)
(require 'ui/writer)

(provide 'init)
;;;; init.el ends here