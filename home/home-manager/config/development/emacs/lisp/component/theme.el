;;; theme.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; No-confirm themes
(setq custom-safe-themes t)

;;;; Custom Theme Folder
;;
(defcustom lem-custom-themes-dir (concat lem-user-dir "custom-themes/")
  "Set a custom themes directory path."
  :group 'lambda-emacs
  :type 'string)

;; Make the custom themes dir.
(mkdir lem-custom-themes-dir t)
(setq-default custom-theme-directory lem-custom-themes-dir)

;; find all themes recursively in custom-theme-folder
(let ((basedir custom-theme-directory))
  (dolist (f (directory-files basedir))
    (if (and (not (or (equal f ".") (equal f "..")))
             (file-directory-p (concat basedir f)))
        (add-to-list 'custom-theme-load-path (concat basedir f)))))

;;;; Disable All Custom Themes
(defun lem-disable-all-themes ()
  "Disable all active themes & reset mode-line."
  (interactive)
  (progn
    (dolist (i custom-enabled-themes)
      (disable-theme i))
    ;; disable window-divider mode
    (window-divider-mode -1)
    ;; revert to mode line
    (setq-default header-line-format nil)
    (setq-default mode-line-format
                  '((:eval
                     (list
                      "%b "
                      "%m "
                      (cond ((and buffer-file-name (buffer-modified-p))
                             (propertize "(**)" 'face `(:foreground "#f08290")))
                            (buffer-read-only "(RO)" ))
                      " %l:%c %0"
                      " "
                      ))))
    (force-mode-line-update)))

;;;; Load Theme Wrapper
(defun lem-load-theme ()
  (interactive)
  (progn
    (lem-disable-all-themes)
    (call-interactively 'load-theme)))

;;;; Toggle Menubar
;; toggle menubar to light or dark
(defun lem-osx-toggle-menubar-theme ()
  "Toggle menubar to dark or light using shell command."
  (interactive)
  (shell-command "dark-mode"))
(defun lem-osx-menubar-theme-light ()
  "Turn dark mode off."
  (interactive)
  (shell-command "dark-mode off"))
(defun lem-osx-menubar-theme-dark ()
  "Turn dark mode on."
  (interactive)
  (shell-command "dark-mode on"))

;;;; Theme toggle
(defun toggle-dark-light-theme ()
  "Flip the active lambda variant between light and dark.
If neither lambda variant is currently active (the user loaded some
other theme), default to `lambda-dark'. The macOS system-appearance
hook is left untouched; the next macOS Light/Dark change will resync."
  (interactive)
  (let* ((current (car custom-enabled-themes))
         (target (if (eq current 'lambda-light) 'lambda-dark 'lambda-light)))
    (lem-disable-all-themes)
    (load-theme target t)))

;;;; After Load Theme Hook
(defvar lem-after-load-theme-hook nil
  "Hook run after a color theme is loaded using `load-theme'.")
(defadvice load-theme (after run-after-load-theme-hook activate)
  "Run `after-load-theme-hook'."
  (run-hooks 'lem-after-load-theme-hook))

;;;; Lambda Themes
;; Set a default theme
(use-package lambda-themes
  :when (and lem-load-extras (locate-library "lambda-themes"))
  :ensure nil
  :init
  (unless (package-installed-p 'lambda-themes)
    (package-vc-install "https://github.com/Lambda-Emacs/lambda-themes.git"))
  :custom
  ;; Custom settings. To turn any of these off just set to `nil'.
  (lambda-themes-set-variable-pitch t)
  (lambda-themes-set-italic-comments t)
  (lambda-themes-set-italic-keywords t))

;; kind-icon needs to have its cache flushed after theme change
(with-eval-after-load 'kind-icon
  (add-hook 'lambda-themes-after-load-theme-hook #'kind-icon-reset-cache))

;;;;; macOS system-appearance dispatch
;; Delegate Light/Dark choice to macOS. The system already does
;; sunrise/sunset when set to Auto, and reflects manual flips
;; instantly -- following it removes every source of drift between
;; Emacs and the rest of the desktop.
;;
;; `ns-system-appearance' (symbol `light' or `dark') is set when an NS
;; frame initializes; `ns-system-appearance-change-functions' fires
;; when the system flips. The change hook does NOT fire at startup --
;; the prior version of this code only registered the hook, which is
;; why initial theme often disagreed with macOS. We apply once at file
;; load to fix that, falling back to `defaults read' so a frameless
;; daemon (which has not bound `ns-system-appearance' yet) still picks
;; the right theme at boot.

(defun lem--system-apply-theme (appearance)
  "Load the lambda variant matching system APPEARANCE.
APPEARANCE is `light' or `dark' from
`ns-system-appearance-change-functions' or `ns-system-appearance'.
No-op when the target is already at the head of
`custom-enabled-themes'."
  (let ((target (pcase appearance
                  ('dark 'lambda-dark)
                  (_     'lambda-light))))
    (unless (eq target (car custom-enabled-themes))
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme target t))))

(defun lem--macos-current-appearance ()
  "Return current macOS system appearance as `light' or `dark'.
Prefers `ns-system-appearance' (set once an NS frame exists); falls
back to `defaults read -g AppleInterfaceStyle' for frameless daemons.
`defaults' returns \"Dark\" when dark mode is on and exits non-zero
when light, so any non-zero exit (or output not containing \"Dark\")
is treated as light."
  (cond
   ((and (boundp 'ns-system-appearance) ns-system-appearance)
    ns-system-appearance)
   ((and (bound-and-true-p sys-mac)
         (executable-find "defaults"))
    (with-temp-buffer
      (let ((exit (call-process "defaults" nil t nil
                                "read" "-g" "AppleInterfaceStyle")))
        (if (and (zerop exit)
                 (string-match-p "Dark" (buffer-string)))
            'dark
          'light))))
   (t 'light)))

(when (bound-and-true-p sys-mac)
  (when (boundp 'ns-system-appearance-change-functions)
    (add-hook 'ns-system-appearance-change-functions
              #'lem--system-apply-theme))
  (lem--system-apply-theme (lem--macos-current-appearance)))

;;; Provide
(provide 'component/theme)
;;; lem-setup-theme.el ends here
