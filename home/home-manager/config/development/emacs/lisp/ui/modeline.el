;;; modeline.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'cl-lib)

(defgroup nano nil
  "N Λ N O"
  :group 'convenience)

(defgroup modeline nil
  "N Λ N O Modeline"
  :group 'theme)

(defcustom modeline-padding '(0.20 . 0.25)
  "Default vertical space adjustment (in fraction of character height)"
  :type '(cons (float :tag "Top spacing")
               (float :tag "Bottom spacing"))
  :group 'modeline)

(defcustom modeline-position #'modeline-header
  "Default position for the nano modeline"

  :type '(choice (const :tag "Top"    modeline-header)
                 (const :tag "Bottom" modeline-footer))
  :group 'modeline)

(defcustom modeline-window-dedicated-symbol '(" " . "")
  "Pairs of strings showing a window is dedicated or not dedicated"
  :type '(cons (string :tag "Window is dedicated" )
               (string :tag "Window is not dedicated"))
  :group 'modeline)

(defface modeline-active
  `((t (:foreground ,(face-foreground 'default)
        :background ,(face-background 'header-line nil t)
        :box (:line-width 6 :color ,(face-background 'default)))))
    "Face for when line is active")

(defface modeline-inactive
  `((t (:inherit (,(when (facep 'boba-faded) 'boba-faded)
                  modeline-active))))
  "Face for when line is inactive")

(defface modeline-status
  `((t (:foreground ,(face-background 'default)
        :background ,(face-foreground 'shadow nil t)
        :inherit bold)))
  "Face for line status")

(defface modeline-button-active-face
  `((t :foreground ,(face-foreground 'default)
       :background ,(face-background 'default)
       :family "Roboto Mono"
       :weight regular
       :box (:line-width 2
             :color ,(face-foreground 'default)
             :style flat-button)))
  "Active button face")

(defface modeline-button-inactive-face
  `((t :foreground ,(face-foreground (if (facep 'boba-faded) 'boba-faded 'default))
       :background ,(face-background 'header-line nil t)
       :family "Roboto Mono"
       :weight regular
       :box (:line-width 2
             :color ,(face-foreground 'default)
             :style flat-button)))
  "Inactive button face.")

(defface modeline-button-highlight-face
  `((t :foreground ,(face-background 'default)
       :background ,(face-foreground 'default)
       :family "Roboto Mono"
       :weight bold))
  "Highlight button face.")

(defvar modeline-base-face nil)

(defun modeline--stroke-width (face)
  "Extract the line width of the box for the given FACE."

  (let* ((box (face-attribute face ':box nil 'default))
         (width (plist-get box ':line-width)))
      (cond ((integerp width) width)
            ((consp width) (car width))
            (t 0))))

;; Nano line faces
(defcustom modeline-faces
  `((header-active      . (modeline-active))
    (header-inactive    . (modeline-inactive))
    (footer-active      . (modeline-active))
    (footer-inactive    . (modeline-inactive))
    (status-RW-active   . (modeline-status))
    (status-RO-active   . (modeline-status))
    (status-**-active   . (modeline-status
                           ,(when (facep 'boba-popout-i) 'boba-popout-i)))
    (name-active        . (bold))
    (primary-active     . ())
    (secondary-active   . (,(when (facep 'boba-faded) 'boba-faded))))
  "Nano line faces.

Each face defined here is used by the modeline depending on the current state (active / inactive). It is ok to define a face for a single state. In such case, the alternative state will use defaults."
  :type '(alist :key-type (symbol :tag "Face")
                :value-type (repeat :tag "inherits" face)))

(defface modeline--empty-face
  `((t (:foreground ,(face-foreground 'default))))
  "Empty face for resetting mode-line / header-line."
  :group nil)

(defvar modeline--selected-window nil
  "Selected window before mode-line was activated.")

(defun modeline--update-selected-window ()
  "Update selected window (before mode-line is active)"
  (setq modeline--selected-window (selected-window)))

(defun modeline--base-face (face-prefix)
  "Return the face for FACE-PREFIX according to current active state."

  (let* ((window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window))
         (state (intern (concat (symbol-name face-prefix)
                                (if active "-active" "-inactive"))))
         (face (cadr (assoc state modeline-faces))))
    face))

(defun modeline-face (&optional face-prefix)
  "Return the face for FACE-PREFIX according to current active state and
make it inherit the base face."

  (let* ((window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window))
         (state (intern (concat (symbol-name face-prefix)
                                (if active "-active" "-inactive"))))
         (face (cdr (assoc state modeline-faces)))
         (face (if modeline-base-face
                   (push modeline-base-face face)
                 face))
         (face (reverse face)))
    `(:inherit ,face)))


(defvar-local modeline-left-fringe-width 0)
(defvar-local modeline-right-fringe-width 0)

(defun modeline--make (left right face-prefix)
  "Build a dynamic mode/header line made of LEFT and RIGHT part,
using the given FACE-PREFIX as the default."

  `(:eval
    (let* ((modeline-base-face (modeline--base-face ',face-prefix))
           (left (mapconcat
                  (lambda (element)
                    (if (stringp element)
                        (propertize element 'face modeline-base-face)
                      (apply (car element) (cdr element))))
                  ',left))
           (right (mapconcat
                   (lambda (element)
                    (if (stringp element)
                        (propertize element 'face modeline-base-face)
                     (apply (car element) (cdr element))))
                   ',right))
           (width (window-width))
           (fringes (window-fringes))
           (left-fringe-pix (car fringes))
           (right-fringe-pix (cadr fringes))
           (outside fringes-outside-margins)
           (left-fringe (if outside -1.0 0.0))
           (left-margin (if outside 0.0 1.0))
           (right-fringe (if outside -1.0 0.0))
           (right-margin (if outside -1.0 0.0))
           (left-max-size (- width (length right) 2))
           (left (if (> (length left) left-max-size)
                     (concat (truncate-string-to-width left left-max-size)
                             (propertize "…" 'face `(:inherit  ,modeline-base-face)))
                   left)))
      (concat (propertize " "
                        'display `(space :align-to (+ left-margin
                                                      (,left-fringe . left-fringe)
                                                      (,left-margin . left-margin))))
            (propertize " " 'face 'fringe
                        'display `(space :width (,left-fringe-pix)))
            left
            (propertize " "
                        'face `(:inherit ,modeline-base-face )
                        'display `(space :align-to (- right-margin
                                                      (,right-fringe . right-fringe)
                                                      (,right-margin . right-margin)
                                                      (,right-fringe-pix)
                                                      1.5
                                                      ,(length right))))
            right
            (propertize " " 'face 'fringe
                        'display `(space :width (,right-fringe-pix)))))))

;; (defun modeline--make (left right face-prefix)
;;   "Build a dynamic mode/header line made of LEFT and RIGHT part,
;; using the given FACE-PREFIX as the default."

;;   `(:eval
;;     (let* ((modeline-base-face (modeline--base-face ',face-prefix))
;;            (left (mapconcat
;;                   (lambda (element)
;;                     (if (stringp element)
;;                         (propertize element 'face modeline-base-face)
;;                       (apply (car element) (cdr element))))
;;                   ',left))
;;            (right (mapconcat
;;                    (lambda (element)
;;                     (if (stringp element)
;;                         (propertize element 'face modeline-base-face)
;;                      (apply (car element) (cdr element))))
;;                    ',right))
;;            (width (window-width))
;;            (fringe (if fringes-outside-margins 0.0 -1.0))
;;            (left-max-size (- width (length right) 2))
;;            (left (if (> (length left) left-max-size)
;;                      (concat (truncate-string-to-width left left-max-size)
;;                              (propertize "…" 'face `(:inherit  ,modeline-base-face)))
;;                    left)))
;;       (concat (propertize " "
;;                 'display `(space :align-to (+ left-margin
;;                                               (,fringe . left-fringe)
;;                                               ( 0.0 . left-margin))))
;;               left
;;               (propertize " "
;;                 'face `(:inherit ,modeline-base-face)
;;                 'display `(space :align-to (- right
;;                                               (,fringe . right-fringe)
;;                                               ( 0.0 . right-margin)
;;                                               ,(length right))))
;;               right))))


(defun modeline--stroke-color (face)
  "Extract the line color of the box for the given FACE."

  (let* ((box (face-attribute face ':box))
         (color (plist-get box ':color)))
    (cond ((stringp color) color)
          (t (face-foreground face nil 'default)))))

(defun modeline--make-text-button (label face state)
  "Make a text button from LABEL and FACE for given STATE."

  (let* ((foreground (face-foreground face nil 'default))
         (background (face-background face nil 'default))
         (label (concat " " label " "))
         ;; We compensate the footer padding with an irregular outer
         ;; box around label (vertical border with a default
         ;; background color). If this is not made the background color
         ;; is the height of the modeline which is not very aesthetic.
         (padding (floor (/ (* (frame-char-height)
                               (+ (car modeline-padding)
                                  (cdr modeline-padding))) 2)))
         (padding (+ padding 0))
         (window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window))
         (face (if active
                   'modeline-active
                 'modeline-inactive)))
    (propertize label
                'face `(:inherit ,face
                        :foreground ,foreground
                        :background ,background))))

(defvar modeline--svg-button-cache nil
  "Cache for modeline buttons")

(defun modeline--make-svg-button (label face state)
  "Make a svg button from LABEL and FACE for given STATE."

  (require 'svg-lib)
  (unless modeline--svg-button-cache
     (setq modeline--svg-button-cache (make-hash-table :test 'equal)))

  (with-memoization
      (gethash (list label (get-text-property 0 'svg-faces label)
                     face state) modeline--svg-button-cache)

    (let* ((svg-faces (get-text-property 0 'svg-faces label))
           (label-face (when svg-faces
                         (alist-get state svg-faces)))
           (stroke (modeline--stroke-width face))
           (tag (if (facep label-face)
                    (svg-lib-tag label label-face :stroke stroke)
                  (apply #'svg-lib-tag label face label-face))) ;; :stroke stroke)))
           (size (image-size tag))
           (width (ceiling (car size))))
      (propertize (make-string width ? ) 'display tag))))

(defun modeline--make-button (button &optional use-svg)
  "Make a button from a BUTTON decription. When USE-SVG is t and
svg-lib is installed, result is a SVG button else, it is a text
button."

  (let* ((label (plist-get button :label))
         (label (if (functionp label)
                    (funcall label)
                  label))
         (state (plist-get button :state))
         (help (plist-get button :help))
         (hook (plist-get button :hook))
         (window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window))
         (face (cond ((not active)          'modeline-button-inactive-face)
                     ((eq state 'highlight) 'modeline-button-highlight-face)
                     ((eq state 'inactive)  'modeline-button-inactive-face)
                     (t                     'modeline-button-active-face)))
         (new-state (cond ((not active)          'inactive)
                          ((eq state 'highlight) 'highlight)
                          ((eq state 'inactive)  'inactive)
                          (t                     'active)))
         (button (if (and use-svg (package-installed-p 'svg-lib))
                     (modeline--make-svg-button label face state)
                   (modeline--make-text-button label face state))))
    (propertize button
                'pointer 'hand
                'label label
                'keymap (let ((map (make-sparse-keymap)))
                          (define-key map [header-line mouse-1] hook)
                          (define-key map [mode-line mouse-1] hook)
                          map)
                'help-echo `(lambda (window object pos)
                              (modeline--update-button-state ,label 'highlight)
                              (let (message-log-max)
                                (message ,help))
                              nil))))

(defun modeline--reset-button-state (&rest args)
  "Reset the state of all the buttons."

  (when (boundp 'modeline--buttons)
    (dolist (buttons (mapcar 'cdr modeline--buttons))
      (dolist (button buttons)
        (unless (eq (plist-get button :state) 'inactive)
          (plist-put button :state 'active)))))
  (force-mode-line-update))

(defun modeline--update-button-state (label state)
  "Update the state of the button LABEL with new STATE and update
other button states."

  (let* ((window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window)))
    (when (and active (boundp 'modeline--buttons))
      (dolist (buttons (mapcar 'cdr modeline--buttons))
        (dolist (button buttons)
          (unless (eq (plist-get button :state) 'inactive)
            (let* ((button-label (plist-get button :label))
                   (button-label (if (functionp button-label)
                                     (funcall button-label)
                                   button-label)))
          (if (string-equal button-label label)
              (plist-put button :state state)
            (plist-put button :state 'active))))))))
  (force-mode-line-update))

(defun modeline-boba-buttons ()
  "Return modeline element for Bobamacs global buttons."
  (let* ((btn-face '(:inherit modeline-active :weight bold))
         (options-btn (propertize
                       " Options "
                       'face btn-face
                       'keymap (let ((m (make-sparse-keymap)))
                                 (define-key m [header-line mouse-1]
                                   (lambda (_e) (interactive "e") (boba-toolbar-toggle)))
                                 (define-key m [header-line mouse-2]
                                   (lambda (_e) (interactive "e") (boba-toolbar-toggle)))
                                 m)
                       'mouse-face 'dashboard-modeline-button-hover-face
                       'help-echo "Toggle context toolbar"))
         (files-btn (propertize
                     " File Tree "
                     'face btn-face
                     'keymap (let ((m (make-sparse-keymap)))
                               (define-key m [header-line mouse-1]
                                 (lambda (_e) (interactive "e") (neotree-toggle)))
                               (define-key m [header-line mouse-2]
                                 (lambda (_e) (interactive "e") (neotree-toggle)))
                               m)
                     'mouse-face 'dashboard-modeline-button-hover-face
                     'help-echo "Toggle file tree"))
         (sidebar-btn (propertize
                       " Sidebar "
                       'face btn-face
                       'keymap (let ((m (make-sparse-keymap)))
                                 (define-key m [header-line mouse-1]
                                   (lambda (_e) (interactive "e") (dashboard-sidebar-toggle)))
                                 (define-key m [header-line mouse-2]
                                   (lambda (_e) (interactive "e") (dashboard-sidebar-toggle)))
                                 m)
                       'mouse-face 'dashboard-modeline-button-hover-face
                       'help-echo "Toggle sidebar"))
         (separator "  "))
    (concat "  " options-btn "  " files-btn "  " sidebar-btn)))

(defun modeline-header (left &optional right default)
  "Install a header line made of LEFT and RIGHT parts. Line can be
made DEFAULT."

  (require 'tooltip)

  (if default
      (setq-default header-line-format (modeline--make left right 'header))
    (setq-local header-line-format (modeline--make left right 'header)))
  (make-local-variable 'modeline--buttons)
  (setq modeline--buttons nil)
  (advice-add 'tooltip-hide :before #'modeline--reset-button-state)
  (face-remap-set-base 'header-line 'modeline--empty-face)
  (add-hook 'post-command-hook #'modeline--update-selected-window))

(defun modeline-footer (left &optional right default)
  "Install a footer line made of LEFT and RIGHT parts. Line can be
made DEFAULT."

  (if default
      (setq-default mode-line-format (modeline--make left right 'header))
    (setq-local mode-line-format (modeline--make left right 'header)))
  (make-local-variable 'modeline--buttons)
  (setq modeline--buttons nil)
  (advice-add 'tooltip-hide :before #'modeline--reset-button-state)
  (face-remap-set-base 'mode-line 'modeline--empty-face)
  (face-remap-set-base 'mode-line-inactive 'modeline-empty-face)
  (add-hook 'post-command-hook #'modeline--update-selected-window))

(defun modeline-buffer-name (&optional name)
  "Buffer name"
  (let* ((buf-name (or name
                       (cond ((buffer-narrowed-p) (format "%s [narrow]" (buffer-name)))
                             (t (buffer-name)))))
         (window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window))
         (face (if active 'modeline-active 'modeline-inactive))
         (has-icons (fboundp 'nerd-icons-icon-for-file))
         (icon (cond ((not has-icons) "")
                     ((buffer-file-name)
                      (concat (nerd-icons-icon-for-file (buffer-file-name) :face face) " "))
                     (major-mode
                      (let ((mode-icon (nerd-icons-icon-for-mode major-mode :face face)))
                        (if mode-icon (concat mode-icon " ") "")))
                     (t ""))))
    (propertize
     (concat icon buf-name)
     'face (modeline-face 'name))))

(defun modeline--resolve-color (face attr)
  "Resolve ATTR (:foreground or :background) color for FACE, with fallback to default face."
  (let ((color (cond
                ((facep face)
                 (if (eq attr :foreground)
                     (face-foreground face nil t)
                   (face-background face nil t)))
                ((and (listp face) (eq (car face) :inherit))
                 (let ((inherited-faces (cadr face))
                       (resolved nil))
                   (unless (listp inherited-faces)
                     (setq inherited-faces (list inherited-faces)))
                   (while (and inherited-faces (not resolved))
                     (let ((f (car inherited-faces)))
                       (setq inherited-faces (cdr inherited-faces))
                       (when (facep f)
                         (setq resolved (if (eq attr :foreground)
                                            (face-foreground f nil t)
                                          (face-background f nil t))))))
                   resolved))
                ((listp face)
                 (let ((resolved nil)
                       (faces face))
                   (while (and faces (not resolved))
                     (let ((f (car faces)))
                       (setq faces (cdr faces))
                       (when (facep f)
                         (setq resolved (if (eq attr :foreground)
                                            (face-foreground f nil t)
                                          (face-background f nil t))))))
                   resolved)))))
    (or color
        (if (eq attr :foreground)
            (face-foreground 'default nil t)
          (face-background 'default nil t))
        (if (eq attr :foreground)
            "black"
          "white"))))

(defun modeline-buffer-status (&optional status padding)
  "Generic prefix to indicate buffer STATUS with vertical PADDING (top . bottom)"
  (let* ((padding (or padding modeline-padding))
         (top (propertize " " 'display `(raise ,(car padding))))
         (bot (propertize " " 'display `(raise ,(- (cdr padding)))))
         (face (cond (buffer-read-only (modeline-face 'status-RO))
                     ((buffer-modified-p) (modeline-face 'status-**))
                     (t (modeline-face 'status-RW)))))
    (concat
     (if (and (display-graphic-p)
              (or (fboundp 'svg-icon) (require 'svg-icon nil t))
              (null status))
         (let* ((icon-name (cond (buffer-read-only "lock-alt")
                                 ((buffer-modified-p) "git-commit")
                                 (t "pencil")))
                (fg (modeline--resolve-color face :foreground))
                (bg (modeline--resolve-color face :background))
                (icon (svg-icon "boxicons" icon-name fg bg)))
           (propertize (concat top (propertize "  " 'display icon) bot) 'face face))
       ;; Fallback for text status or non-graphic mode
       (let* ((text (or status
                        (cond (buffer-read-only "RO")
                              ((buffer-modified-p) "**")
                              (t "RW"))))
              (padded-text (concat " " text " ")))
         (propertize (concat top padded-text bot) 'face face)))
     " ")))


(defun modeline-buttons (buttons &optional use-svg group)
  "Clickable BUTTONS in text or svg mode depending on
USE-SVG. BUTTONS is a list of cons (label. (hook . help)) where
hook is an interactive function that is called when the button is
clicked and help is the tooltip help message. GROUP (default to
0) is an arbitrary optional index of the group this button
belongs to.If you want to have button highlight when the mouse
hovers a button, tooltip mode needs to be active and tooltip
delay needs to be set to 0."

  (unless (and (boundp 'modeline--buttons)
               modeline--buttons
               (assoc (or group 0) modeline--buttons))
    (unless (boundp 'modeline--buttons)
      (make-local-variable 'modeline--buttons))
    (let* ((group (or group 0))
           (buttons (mapcar (lambda (button)
                              (list ':label (car button)
                                    ':state 'active
                                    ':help (cddr button)
                                    ':hook (cadr button)))
                            buttons)))
      (if (cdr (assoc group modeline--buttons))
          (setf (cdr (assoc group modeline--buttons)) buttons)
        (add-to-list 'modeline--buttons (cons group buttons)))))

  (let* ((buttons (cdr (assoc (or group 0) modeline--buttons)))
         (buttons (if (and use-svg (package-installed-p 'svg-lib))
                      (mapconcat (lambda (button)
                                   (modeline--make-button button t))
                                 buttons (propertize " " 'face (modeline-face)))
                    (mapconcat (lambda (button)
                                 (modeline--make-button button nil))
                               buttons (propertize " " 'face (modeline-face))))))
    (if use-svg
        (propertize buttons 'face (modeline-face))
      buttons)))

(defun modeline-file-size ()
  "File size in human readable format"

  (if-let* ((file-name (buffer-file-name))
            (file-attributes (file-attributes file-name))
            (file-size (file-attribute-size file-attributes))
            (file-size (file-size-human-readable file-size)))
      (propertize (format "(%s)" file-size)
                  'face (modeline-face 'primary))
    ""))

(defun modeline-cursor-position (&optional format)
  "Cursor position using given FORMAT."

  (let ((format (or format "%l:%c ")))
    (propertize (format-mode-line format)
                'face (modeline-face 'secondary))))

(defun modeline-buffer-line-count ()
  "Buffer total number of lines"

  (save-excursion
    (goto-char (point-max))
    (propertize
     (format-mode-line "(%l lines)")
     'face (modeline-face 'primary))))

(defun modeline-window-dedicated (&optional dedicated not-dedicated)
  "Pin symbol when window is dedicated"

  (propertize (if (window-dedicated-p)
                  (or dedicated (car modeline-window-dedicated-symbol))
                (or not-dedicated (cdr modeline-window-dedicated-symbol)))
              'face (modeline-face 'secondary)))

(defun modeline-git-info (&optional symbol)
  "Git information as (branch, file status)"

  (when vc-mode
      (when-let* ((file (buffer-file-name))
                  (branch (substring-no-properties vc-mode 5))
                  (state (vc-state file)))
        (propertize (format "(%s%s, %s)" (or symbol " ") branch state)
                    'face (modeline-face 'primary)))))

(defun modeline-primary-info (text)
  "Information using primary face"

  (propertize text 'face (modeline-face 'primary)))

(defun modeline-secondary-info (text)
  "Information using primary face"

  (propertize text 'face (modeline-face 'secondary)))

(defun modeline-mu4e-search-filter ()
  "Mu4e current search"

  (propertize (mu4e-last-query) 'face (modeline-face 'name)))

(defun modeline-mu4e-context ()
  "Mu4e current context"

  (let* ((context (mu4e-context-current))
         (name (if context (mu4e-context-name context) "none")))
    (propertize (format "[%s] " name)
                'face (modeline-face 'secondary))))

(defun modeline-mu4e-raw-context ()
  "Mu4e current context (raw form for button)"

  (let* ((context (mu4e-context-current))
         (name (if context (mu4e-context-name context) "NONE")))
    (upcase name)))

(defun modeline-mu4e-message-to ()
  "Return the recipients of a message, separating me from others"

  (with-current-buffer "*mu4e-headers*"
    (let* ((msg (mu4e-message-at-point))
           (list (memq 'list (plist-get msg :flags)))
           (cc (mapcar (lambda (item)
                         (downcase (plist-get item :email)))
                       (plist-get msg :cc)))
           (to (mapcar (lambda (item)
                         (downcase (plist-get item :email)))
                       (plist-get msg :to)))
           (to-names (mapcar (lambda (item)
                               (if (stringp (plist-get item :name))
                                   (capitalize (downcase (plist-get item :name)))
                                 (plist-get item :email)))
                             (plist-get msg :to)))
           (all (cl-union to cc))
           (me (mapcar #'downcase (mu4e-personal-addresses)))
           (me (cl-intersection all me :test #'string-equal))
           (others (cl-set-difference all me :test #'string-equal)))
      (cond (list
             (concat "to " (car to-names)))
            ((= (length others) 0)
             "to me")
            ((and (> (length others) 0) (< (length others) (length all)))
             (format "to me (+%d recipients)" (length others)))
            ((and (= (length others) 1))
             (format "to %s" (car to-names)))
            (t
             (format "to %s (+%d recipients)" (car to-names) (1- (length others))))))))

(defun modeline-mu4e-message-from ()
  "Return the sender of the message that can be me or a name"

  (with-current-buffer "*mu4e-headers*"
    (let* ((msg (mu4e-message-at-point))
           (me (mapcar #'downcase (mu4e-personal-addresses)))
           (from (mu4e-message-field msg :from))
           (from-name (plist-get (car from) :name))
           (from-email (plist-get (car from) :email)))
      (cond ((member from-email me) "Me")
            ((stringp from-name)    (capitalize (downcase from-name)))
            (t                      from-email)))))


(defun modeline-mu4e-view-in-xwidget ()
  (interactive)
  (with-current-buffer "*mu4e-headers*"
    (let ((msg (mu4e-message-at-point)))
      (mu4e-action-view-in-xwidget msg))))

(defun modeline-mu4e-context-next ()
  "Switch to next mu4e context"

  (interactive)
  (let* ((current (mu4e-context-name (mu4e-context-current)))
         (contexts (mapcar (lambda (context)
                             (mu4e-context-name context))
                           mu4e-contexts))
         (index (mod (1+ (cl-position current contexts))
                     (length contexts)))
         (current (nth index contexts)))
    (mu4e-context-switch t current)))

(defun modeline-mu4e-message-subject ()
  "Mu4e message subject"

  (let* ((msg (mu4e-message-at-point))
         (subject (mu4e-message-field msg :subject)))
    (propertize (format "%s" subject)
                'face (modeline-face 'name))))

(defun modeline-mu4e-message-date ()
  "Mu4e message date"

  (let* ((msg (mu4e-message-at-point))
         (date (mu4e-message-field msg :date)))
    (propertize (format-time-string "%d %b %Y at %H:%M" date)
                'face (modeline-face 'secondary))))

(defun modeline-pdf-page ()
  "PDF view mode page number / page total"

  (let ((page-current (image-mode-window-get 'page))
        (page-total (pdf-cache-number-of-pages)))
    (propertize (format "%d/%d " page-current page-total)
                'face (modeline-face 'secondary))))

(defun modeline-elfeed-entry-status ()
  "Elfeed entry status"

  (let* ((feed (elfeed-entry-feed elfeed-show-entry))
         (feed-title (plist-get (elfeed-feed-meta feed) :title)))
    (modeline-buffer-status feed-title)))

(defun modeline-elfeed-entry-title ()
  "Elfeed entry title"

  (let* ((title (elfeed-entry-title elfeed-show-entry))
         (title (string-replace "%" "%%" title)))
    (propertize title 'face (modeline-face 'name))))

(defun modeline-elfeed-search-filter ()
  "Elfeed search filter"

  (propertize
   (if (and (not (zerop (elfeed-db-last-update)))
            (> (elfeed-queue-count-total) 0))
       (let ((total (elfeed-queue-count-total))
             (in-process (elfeed-queue-count-active)))
         (format "%d jobs pending, %d active"  (- total in-process) in-process))
     (cond (elfeed-search-filter-active "")
           ((string-match-p "[^ ]" elfeed-search-filter) elfeed-search-filter)
           (t "")))
   'face (modeline-face 'name)))

(defun modeline-elfeed-search-count ()
  "Elfeed search statistics"

  (propertize (cond ((zerop (elfeed-db-last-update)) "")
                    ((> (elfeed-queue-count-total) 0) "")
                    (t (concat (elfeed-search--count-unread) " ")))
   'face (modeline-face 'secondary)))

(defun modeline-elpher-protocol ()
  "Elpher protocol"

  (propertize (format "(%s)"
   (elpher-address-protocol (elpher-page-address elpher-current-page)))
   'face (modeline-face 'primary)))

(defun modeline-elpher-title ()
  "Elpher protocol"

  (propertize
   (elpher-page-display-string elpher-current-page)
   'face (modeline-face 'name)))

(defun modeline-date (&optional date format)
  "Date using given FORMAT and DATE"

  (propertize (format-time-string (or format "%A %-e %B %Y") date)
              'face (modeline-face 'secondary)))

(defun modeline-org-agenda-date (&optional format)
  "Date at point in org agenda  using given FORMAT"

  (when-let* ((day (or (org-get-at-bol 'ts-date)
                       (org-get-at-bol 'day)))
              (date (calendar-gregorian-from-absolute day))
              (day (nth 1 date))
              (month (nth 0 date))
              (year (nth 2 date))
              (date (encode-time 0 0 0 day month year)))
    (propertize (format-time-string (or format "%A %-e %B %Y") date)
                'face (modeline-face 'secondary))))

(defun modeline-term-shell-name ()
  "Term shell name"

  (propertize shell-file-name
              'face (modeline-face 'name)))

(defun modeline-term-shell-mode ()
  "Term shell mode"

  (propertize (if (term-in-char-mode)
                  "(char mode)"
                "(line mode)")
               'face (modeline-face 'primary)))

(defun modeline-eat-shell-mode ()
  "Eat shell mode"

  (propertize (cond (eat--semi-char-mode "(semi-char mode)")
                    (eat--char-mode "(char mode)")
                    (eat--line-mode "(line mode)")
                    (t "(unknown mode)"))
               'face (modeline-face 'primary)))

(defun modeline-default-directory (&optional max-length)
  "Term current directory"

  (let* ((max-length (or max-length 32))
         (dir default-directory)
         (path (reverse (split-string (abbreviate-file-name dir) "/")))
         (output ""))
    (when (and path (equal "" (car path)))
      (setq path (cdr path)))
    (while (and path (< (length output) (- max-length 0)))
      (setq output (concat (car path) "/" output))
      (setq path (cdr path)))
    (when path
      (setq output (concat "…/" output)))
    (propertize output 'face (modeline-face 'secondary))))

(defun modeline-xwidget-uri ()
  "xwidget URI"

  (propertize (xwidget-webkit-uri (xwidget-at (point-min)))
              'face (modeline-face 'name)))

(defun modeline-org-buffer-name (&optional name)
  "Org buffer name"
  (let* ((buf-name (cond (name name)
                          ((buffer-narrowed-p)
                           (format "%s [%s]" (or (buffer-base-buffer) (buffer-name))
                                   (org-link-display-format
                                    (substring-no-properties
                                     (or (org-get-heading 'no-tags) "-")))))
                          (t (buffer-name))))
         (window (get-buffer-window (current-buffer)))
         (active (eq window modeline--selected-window))
         (face (if active 'modeline-active 'modeline-inactive))
         (has-icons (fboundp 'nerd-icons-icon-for-mode))
         (icon (if has-icons (concat (nerd-icons-icon-for-mode 'org-mode :face face) " ") "")))
    (propertize
     (concat icon buf-name)
     'face (modeline-face 'name))))

(defun modeline-org-outline-path ()
  "Org outline path"

  (let ((path (org-with-point-at (org-get-at-bol 'org-marker)
                (org-display-outline-path nil nil " » " t))))
    (propertize (substring-no-properties path)
                'face (modeline-face 'name))))

(defun modeline-org-capture-description ()
  "Org capture descrioption"

  (let* ((header (nth 4 (org-heading-components)))
         (header (or header ""))
         (header (org-link-display-format header))
         (header (replace-regexp-in-string org-ts-regexp3 "" header))
         (header (string-trim header))
         (header (substring-no-properties header)))
    (propertize (format "(%s)" header)
                ;; (format "(%s)" (substring-no-properties (org-capture-get :description)))
                'face (modeline-face 'primary))))

(defun modeline-prog-mode (&optional default)
  "Nano line for prog mode. Can be made DEFAULT mode."

  (funcall modeline-position
            '((modeline-buffer-status) " "
              (modeline-buffer-name) " "
              (modeline-git-info))
            '((modeline-cursor-position)
              (modeline-window-dedicated))
            default))

(defun modeline-text-mode (&optional default)
  "Nano line for text mode. Can be made DEFAULT mode."

  (funcall modeline-position
           '((modeline-buffer-status) " "
             (modeline-buffer-name) " "
             (modeline-git-info))
           '((modeline-cursor-position)
             (modeline-window-dedicated))
           default))

(defun modeline-elpher-mode ()
  "Nano line for elpher mode"

  (setq elpher-use-header nil)
  (funcall modeline-position
           '((modeline-buffer-status "GEM") " "
             (modeline-elpher-title) " "
             (modeline-elpher-protocol))
           '((modeline-cursor-position)
             (modeline-window-dedicated))))

(defun modeline-org-mode ()
  "Nano line for org mode"

  (funcall modeline-position
           '((modeline-buffer-status) " "
             (modeline-org-buffer-name) " "
             (modeline-git-info))
           '((modeline-cursor-position)
             (modeline-window-dedicated))))

(defun modeline-pdf-mode ()
  "Nano line for text mode"

  (funcall modeline-position
           '((modeline-buffer-status "PDF") " "
             (modeline-buffer-name) " "
             (modeline-file-size))
           '((modeline-pdf-page)
             (modeline-window-dedicated))))

(defun modeline-mu4e-headers-mode ()
  "Nano line for mu4e headers mode with a button to change context"

  (let ((buttons '((modeline-mu4e-raw-context . (modeline-mu4e-context-next . "Switch to next context")))))
  (funcall modeline-position
           '((modeline-buffer-status "MAIL") " "
             (modeline-mu4e-search-filter))
             `((modeline-buttons ,buttons t) " "
             (modeline-window-dedicated)))))


(defun modeline-mu4e-message-mode ()
  "Nano line for mu4e message mode with several buttons for most
common action"

  (let ((buttons '(("[bootstrap:archive]" . (mu4e-view-mark-for-refile . "Archive message"))
                   (":bootstrap:trash]" . (mu4e-view-mark-for-trash . "Delete message"))
                   ("[bootstrap:file-richtext]". (modeline-mu4e-view-in-xwidget . "View message as HTML"))
                   ("[bootstrap:folder]". (mu4e-headers-mark-for-move . "Move message"))
                   ("[bootstrap:tag]". (mu4e-headers-mark-for-tag . "Tag message"))
                   ("[bootstrap:reply]". (mu4e-compose-reply . "Reply to message"))
                   ("[bootstrap:forward]". (mu4e-compose-forward . "Forward message")))))
    (funcall modeline-position
             `((modeline-buffer-status "FROM") " "
               (modeline-buffer-name ,(modeline-mu4e-message-from)) " "
               (modeline-primary-info ,(modeline-mu4e-message-to)))
             `((modeline-mu4e-message-date) " "
               ;; (modeline-buttons ,buttons t) " "
               (modeline-window-dedicated)))))

(defun modeline-mu4e-compose-mode ()
  "Nano line for mu4e compose mode"

  (let ((buttons '(("[bootstrap:download]" . (save-buffer . "Save message"))
                   ("[bootstrap:paperclip]" . (mml-attach-file . "Attach file"))
                   ("[bootstrap:lock]" . (mml-secure-message-encrypt . "Encrypt message"))
                   ("[bootstrap:check]" . (mml-secure-message-sign . "Sign message"))
                   ("[bootstrap:send]" . (message-send-and-exit . "Send message")))))
    (funcall modeline-position
             `((modeline-buffer-status "DRAFT") " "
               (modeline-buffer-name "Message"))
             `((modeline-buttons ,buttons t) " "
               (modeline-window-dedicated)))))

(defun modeline-elfeed-entry-mode ()
  "Nano line for elfeed entry mode"

  (funcall modeline-position
           '((modeline-elfeed-entry-status) " "
             (modeline-elfeed-entry-title))))

(defun modeline-elfeed-search-mode ()
  "Nano line for elfeed search mode"

  (add-hook 'elfeed-search-update-hook #'force-mode-line-update)
  (funcall modeline-position
           '((modeline-buffer-status "NEWS") " "
             (modeline-elfeed-search-filter))
           '((modeline-elfeed-search-count)
             (modeline-window-dedicated))))

(defun modeline-term-mode ()
  "Nano line for term mode"

  (funcall modeline-position
           '((modeline-buffer-status ">_") " "
             (modeline-term-shell-name) " "
             (modeline-term-shell-mode))
           '((modeline-default-directory) " "
             (modeline-window-dedicated))))

(defun modeline-eat-mode ()
  "Nano line for term (eat) mode"

  (funcall modeline-position
           '((modeline-buffer-status ">_") " "
             (modeline-term-shell-name) " "
             (modeline-eat-shell-mode))
           '((modeline-default-directory) " "
             (modeline-window-dedicated))))

(defun modeline-xwidget-mode ()
  "Nano line for xwidget mode"

  (funcall modeline-position
           '((modeline-buffer-status "URL") " "
             (modeline-xwidget-uri))
           '((modeline-window-dedicated))))

(defun modeline-message-mode ()
  "Nano line for messages mode"

  (funcall modeline-position
           '((modeline-buffer-status "LOG") " "
             (modeline-buffer-name) " "
             (modeline-buffer-line-count))
           '((modeline-window-dedicated))))

(defun modeline-org-capture-mode ()
  "Nano line for org capture mode"

  (defun modeline-org-capture-filename ()
    (buffer-file-name (org-base-buffer (current-buffer))))

  (let* ((filename (modeline-org-capture-filename))
         (save (format "Save entry to %s" filename))
         (buttons `(("SAVE" . (org-capture-finalize . ,save))
                    ("CANCEL" . (org-capture-kill . "Delete entry"))
                    ("[bootstrap:arrows-expand]" . (delete-other-windows . "expand"))
                    )))
    (funcall modeline-position
             `((modeline-buffer-status "ORG") " "
               (modeline-buffer-name "Capture") " "
               (modeline-org-capture-description))
             `((modeline-buttons ,buttons t) " "
               (modeline-window-dedicated)))))

(defun modeline-org-agenda-mode ()
  "Nano line for org agenda mode"

  (add-hook 'post-command-hook #'force-mode-line-update)
  (funcall modeline-position
            '((modeline-buffer-status "ORG") " "
              (modeline-buffer-name "Agenda"))
            '((modeline-org-agenda-date) " "
              (modeline-window-dedicated))))

(defun modeline-dashboard-mode ()
  "Nano line for dashboard mode."
  (let* ((page (bound-and-true-p dashboard-current-page))
         (status-tag (cond ((eq page 'files) "BOBA/FILES")
                           ((eq page 'notes) "BOBA/NOTES")
                           (t "BOBA/HOME"))))
    (funcall modeline-position
             `((modeline-buffer-status ,status-tag) " "
               (modeline-buffer-name "Bobamacs"))
             '((modeline-dashboard-buttons)))))

;; Enable modeline hooks
(add-hook 'prog-mode-hook            #'modeline-prog-mode)
(add-hook 'text-mode-hook            #'modeline-text-mode)
(add-hook 'org-mode-hook             #'modeline-org-mode)
(add-hook 'term-mode-hook            #'modeline-term-mode)
(add-hook 'eat-mode-hook             #'modeline-eat-mode)
(add-hook 'messages-buffer-mode-hook #'modeline-message-mode)
(add-hook 'org-capture-mode-hook     #'modeline-org-capture-mode)
(add-hook 'org-agenda-mode-hook      #'modeline-org-agenda-mode)
(add-hook 'dashboard-mode-hook       #'modeline-dashboard-mode)

;; Make text-mode modeline the default fallback
(modeline-text-mode t)

(provide 'ui/modeline)
(provide 'boba-modeline)
;;; modeline.el ends here
