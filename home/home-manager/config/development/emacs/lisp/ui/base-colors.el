;;; base-colors.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(defgroup nano '()
  "Faces and colors for the nano emacs theme")

;; Derive our default color set from classic Emacs faces.
;; This allows dropping nano components into already themed Emacsen with varying
;; degrees of visual appeal.
;;
;; We memorize the default colorset in this var in order not to confuse
;; customize: the STANDARD argument of defcustom gets re-evaluated by customize
;; to determine if the current value is default or not.
(defvar boba-base-colors--defaults
  `((foreground . ,(face-foreground 'default nil t))
    (background . ,(face-background 'default nil t))
    (highlight . ,(face-background 'fringe nil t))
    (critical . ,(face-foreground 'error nil t))
    (salient . ,(face-foreground 'font-lock-keyword-face nil t))
    (strong . ,(face-foreground 'default nil t))
    (popout . ,(face-foreground 'font-lock-string-face nil t))
    (subtle . ,(face-background 'mode-line-inactive nil t))
    (faded . ,(face-foreground 'shadow nil t))))

(defun boba-base-colors--get (name)
  "Get default color associated with symbol NAME."
  (cdr (assoc name boba-base-colors--defaults)))

(defcustom theme-color-foreground (boba-base-colors--get 'foreground)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-background (boba-base-colors--get 'background)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-highlight (boba-base-colors--get 'highlight)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-critical (boba-base-colors--get 'critical)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-salient (boba-base-colors--get 'salient)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-strong (boba-base-colors--get 'strong)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-popout (boba-base-colors--get 'popout)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-subtle (boba-base-colors--get 'subtle)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-faded (boba-base-colors--get 'faded)
  ""
  :type 'color
  :group 'theme)

(defcustom theme-color-modeline-bg nil
  "Modeline background color."
  :type 'color
  :group 'theme)

(provide 'ui/base-colors)
