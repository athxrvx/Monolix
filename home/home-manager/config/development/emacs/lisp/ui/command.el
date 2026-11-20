;;; command.el --- Atomic Emacs quick-command module -*- lexical-binding: t; -*-

;; A native implementation of boba-command (https://github.com/rougier/boba-command)
;; for the Atomic Emacs configuration.
;;
;; Instead of the minibuffer, the user types directly in the header-line of the
;; current buffer.  RET executes; C-g aborts.  Normal editing keys work inside
;; the command input (C-a, C-e, C-k, yank, kill-ring, etc.).
;;
;; Entry points
;; ─────────────────────────────────────────────────────────────────
;;   boba-command               — generic text input from the header-line
;;   boba-command-x             — M-x analogue via boba-command
;;   boba-command-shell         — synchronous shell command (blocks until done)
;;   boba-command-async-shell   — asynchronous shell command (fires & forgets)
;;   boba-capture-todo          — capture a TODO org item to inbox
;;   boba-capture-meeting       — capture a meeting org item to agenda
;;   boba-capture-link          — capture an org link to inbox
;;
;; Keybindings (SPC leader via general.el)
;; ─────────────────────────────────────────────────────────────────
;;   SPC ; x   — boba-command-x
;;   SPC ; !   — boba-command-shell
;;   SPC ; &   — boba-command-async-shell
;;   SPC ; c t — boba-capture-todo
;;   SPC ; c m — boba-capture-meeting
;;   SPC ; c l — boba-capture-link

;;; Requirements:

(require 'ui/faces)
(require 'ui/theme)

(eval-when-compile
  (require 'org nil t))

;;; Forward declarations for byte compiler:

(defvar org-heading-regexp)
(defvar org-stored-links)
(defvar org-link-file-path-type)
(defvar boba-modeline-space-top)
(defvar boba-modeline-space-bottom)
(defvar modeline-mu4e-view-hook)

(declare-function org-find-exact-headline-in-buffer "org")
(declare-function org-refile "org")
(declare-function org-insert-link "org")
(declare-function org-mark-ring-push "org-compat")
(declare-function org-mark-ring-goto "org-compat")
(declare-function org-store-link "ol")
(declare-function modeline-mu4e-view-hook "ui/mu4e" nil t)

;; ═══════════════════════════════════════════════════════════════════════════
;; 1. Custom group & faces
;; ═══════════════════════════════════════════════════════════════════════════

(defgroup boba-command nil
  "Atomic Emacs quick-command — input from the header-line."
  :group 'nano)

(defface boba-command-face nil
  "Base face for the boba-command header-line strip."
  :group 'boba-command)

(defface boba-command-prompt-face nil
  "Face for the prompt label (left side)."
  :group 'boba-command)

(defface boba-command-region-face nil
  "Face for an active region inside the command input."
  :group 'boba-command)

(defface boba-command-cursor-face nil
  "Face for the in-line cursor character."
  :group 'boba-command)

;; ═══════════════════════════════════════════════════════════════════════════
;; 2. Core engine
;; ═══════════════════════════════════════════════════════════════════════════

(defun boba-command--update (prompt text)
  "Write PROMPT + TEXT into the current buffer's header-line.
This is the single rendering point; advise it to change the layout."
  (setq-local header-line-format (concat prompt text)))

(defun boba-command--process (current-buffer command-buffer prompt)
  "Render the content of COMMAND-BUFFER into CURRENT-BUFFER's header-line.
PROMPT is the already-propertised prompt string."
  (with-current-buffer command-buffer
    (let* ((raw   (buffer-substring (point-min) (point-max)))
           ;; right-align a faint spacer so the cursor doesn't hug the edge
           (text  (concat raw " "
                          (propertize " " 'display '(space :align-to (- right 2)))
                          (propertize " " 'face 'boba-faded)))
           (point (point))
           (eol   (= point (point-max)))
           (rbeg  (when (use-region-p) (1- (region-beginning))))
           (rend  (when (use-region-p) (region-end))))

      ;; cursor indicator
      (add-face-text-property (1- point) point 'boba-command-cursor-face t text)
      ;; optional region highlight
      (when (and rbeg rend)
        (add-face-text-property rbeg rend 'boba-command-region-face t text))

      ;; truncate long input to fit available width
      (let ((avail (- (window-width) (length prompt) 1)))
        (when (> point avail)
          (setq text (concat "…" (substring text (- point avail)))))
        (when (> (length text) (1+ avail))
          (setq text (concat (substring text 0 avail)
                             (unless eol "…")))))

      (with-current-buffer current-buffer
        (boba-command--update prompt text))
      (force-mode-line-update))))

;;;###autoload
(defun boba-command (&optional prompt hook message)
  "Read text from the header-line and return it as a string.

PROMPT  — label shown to the left (default: \"Command\").
HOOK    — called with the command buffer current before input starts;
          use it to seed initial text, e.g. (lambda () (insert date)).
MESSAGE — string shown in the echo area while waiting for input.

Returns the entered string, or nil if the user pressed C-g."
  (interactive)
  (let* ((message        (or message ""))
         (saved-mode     mode-line-format)
         (saved-cursor   cursor-type)
         (saved-header   header-line-format)
         ;; Remap header-line appearance while the command strip is active
         (cookie (face-remap-add-relative
                  'header-line
                  :foreground (face-attribute 'boba-command-face :foreground nil 'default)
                  :background (face-attribute 'boba-command-face :background nil 'default)
                  :underline  nil
                  :overline   nil
                  :height     (face-attribute 'boba-command-face :height     nil 'default)
                  :weight     (face-attribute 'boba-command-face :weight     nil 'default)
                  :box        (face-attribute 'boba-command-face :box        nil 'default)))
         (result         nil)
         (current-buffer (current-buffer))
         (current-window (selected-window))
         ;; Build the prompt string, respecting boba-modeline vertical spacing
         (prompt-raw     (concat
                          (if (boundp 'boba-modeline-space-top)
                              (propertize " " 'display `(raise ,boba-modeline-space-top))
                            "")
                          (or prompt "Command")
                          (if (boundp 'boba-modeline-space-bottom)
                              (propertize " " 'display `(raise ,boba-modeline-space-bottom))
                            "")))
         (prompt-str     (concat (propertize prompt-raw 'face 'boba-command-prompt-face)
                                 " "))
         (command-buffer (get-buffer-create " *boba-command*")))

    (unwind-protect
        (progn
          (setq-local cursor-type nil)
          (catch 'done
            (with-current-buffer command-buffer
              (let ((inhibit-read-only t)) (erase-buffer))
              (when hook (funcall hook))
              (boba-command--process current-buffer command-buffer prompt-str)

              (while t
                (let* ((event (read-key-sequence message))
                       (key   (key-description event)))

                  ;; ── Confirm ──────────────────────────────────────────
                  (when (string= key "RET")
                    (let ((text (buffer-substring (point-min) (point-max))))
                      (throw 'done (if (> (length text) 0) text nil))))

                  ;; ── Abort ────────────────────────────────────────────
                  (when (string= key "C-g")
                    (if (region-active-p)
                        (deactivate-mark)
                      (throw 'done nil)))

                  ;; ── Scroll the underlying buffer (mouse wheel) ───────
                  (when (member key '("<wheel-up>" "<wheel-down>"
                                     "<wheel-left>" "<wheel-right>"))
                    (with-current-buffer current-buffer
                      (set-window-buffer current-window current-buffer t)
                      (mwheel-scroll (aref event 0))))

                  ;; ── Forward every other key into the command buffer ───
                  (unless (member key '("C-g" "<wheel-up>" "<wheel-down>"
                                       "<wheel-left>" "<wheel-right>"))
                    (condition-case nil
                        (with-current-buffer command-buffer
                          (set-window-buffer current-window command-buffer t)
                          (execute-kbd-macro (kbd key)))
                      ((beginning-of-buffer end-of-buffer text-read-only))))

                  ;; Restore the visible buffer and refresh the strip
                  (set-window-buffer current-window current-buffer t)
                  (boba-command--process current-buffer command-buffer prompt-str))))))

      ;; ── Always restore state on exit ─────────────────────────────────
      (with-current-buffer current-buffer
        (setq-local mode-line-format    saved-mode)
        (setq-local cursor-type         saved-cursor)
        (setq-local header-line-format  saved-header)
        (face-remap-remove-relative cookie)
        (force-mode-line-update))
      (when (buffer-live-p (get-buffer " *boba-command*"))
        (kill-buffer " *boba-command*"))
      (switch-to-buffer current-buffer))

    result))

;; ═══════════════════════════════════════════════════════════════════════════
;; 3. Shell commands
;; ═══════════════════════════════════════════════════════════════════════════

;;;###autoload
(defun boba-command-shell ()
  "Prompt for a shell command in the header-line and run it synchronously.
Output appears in *Shell Command Output*."
  (interactive)
  (when-let ((cmd (boba-command ">_" nil "Shell command (RET to run, C-g to abort)")))
    (shell-command cmd)
    (when (get-buffer "*Shell Command Output*")
      (switch-to-buffer "*Shell Command Output*"))))

;;;###autoload
(defun boba-command-async-shell ()
  "Prompt for a shell command in the header-line and run it asynchronously.
Output streams into *Async Shell Command*; Emacs stays fully responsive."
  (interactive)
  (when-let ((cmd (boba-command "&_" nil "Async shell command (RET to run, C-g to abort)")))
    (async-shell-command cmd)))

;; ═══════════════════════════════════════════════════════════════════════════
;; 4. M-x analogue
;; ═══════════════════════════════════════════════════════════════════════════

;;;###autoload
(defun boba-command-x ()
  "Run an interactive command chosen via the header-line prompt."
  (interactive)
  (when-let ((cmd (boba-command "M-x" nil "Enter command name")))
    (let ((sym (intern-soft cmd)))
      (if (and sym (commandp sym))
          (command-execute sym)
        (user-error "No such command: %s" cmd)))))

;; ═══════════════════════════════════════════════════════════════════════════
;; 5. Org-capture helpers
;; ═══════════════════════════════════════════════════════════════════════════

(defun boba-capture--refile (file &optional headline)
  "Refile the current Org heading to FILE under optional HEADLINE."
  (unless (featurep 'org) (require 'org))
  (let* ((headline (or headline ""))
         (org-complex-heading-regexp-format org-heading-regexp)
         (pos (with-current-buffer (find-file-noselect file)
                (org-find-exact-headline-in-buffer headline))))
    (org-refile nil nil (list "" file nil pos))))

;;;###autoload
(defun boba-capture-todo ()
  "Capture a TODO item from the header-line and refile to ~/Documents/org/inbox.org."
  (interactive)
  (when-let ((text (boba-command "TODO" nil "Enter TODO — RET to save, C-g to abort")))
    (let ((inhibit-message t)
          (buf (current-buffer)))
      (with-temp-buffer
        (insert (format "* TODO %s :@TODO:" text))
        (goto-char (point-min))
        (org-mark-ring-push)
        (boba-capture--refile "~/Documents/org/inbox.org")
        (org-mark-ring-goto))
      (switch-to-buffer buf))))

;;;###autoload
(defun boba-capture-meeting ()
  "Capture a MEETING item from the header-line and refile to ~/Documents/org/agenda.org."
  (interactive)
  (let* ((template (format-time-string " <%+4Y-%m-%d %a %%02d:00-%%02d:00>"))
         (hour     (string-to-number (format-time-string "%H")))
         (initial  (format template hour (1+ hour))))
    (when-let ((text (boba-command "MEETING"
                                   (lambda () (insert initial))
                                   "Enter meeting timestamp — RET to save, C-g to abort")))
      (let ((inhibit-message t)
            (buf (current-buffer)))
        (with-temp-buffer
          (insert (format "* %s :@MEETING:" text))
          (goto-char (point-min))
          (org-mark-ring-push)
          (boba-capture--refile "~/Documents/org/agenda.org" "Future")
          (org-mark-ring-goto))
        (switch-to-buffer buf)))))

;;;###autoload
(defun boba-capture-link ()
  "Store the link at point, prompt for a name via the header-line, then refile."
  (interactive)
  (let ((inhibit-message t))
    (setq org-link-file-path-type 'absolute)
    (call-interactively #'org-store-link)
    (let ((initial (nth 1 (car org-stored-links))))
      (when-let ((name (boba-command "LINK"
                                     (lambda () (insert (or initial "")))
                                     "Link name — RET to save, C-g to abort")))
        (let ((inhibit-message t)
              (buf (current-buffer)))
          (with-temp-buffer
            (insert "* ")
            (org-insert-link nil (car (pop org-stored-links)) name)
            (insert " :@LINK:")
            (org-mark-ring-push)
            (boba-capture--refile "~/Documents/org/inbox.org" "")
            (org-mark-ring-goto))
          (switch-to-buffer buf))))))

;; ═══════════════════════════════════════════════════════════════════════════
;; 6. mu4e mail helpers  (loaded only when mu4e is present)
;; ═══════════════════════════════════════════════════════════════════════════

(defun boba-command-mail-reply ()
  "Quick one-line mail reply via the header-line."
  (interactive)
  (when (fboundp 'modeline-mu4e-view-hook)
    (remove-hook 'mu4e-view-mode-hook #'modeline-mu4e-view-hook))
  (boba-command "REPLY" nil "Reply to sender"))

(defun boba-command-mail-forward ()
  "Quick one-line mail forward via the header-line."
  (interactive)
  (when (fboundp 'modeline-mu4e-view-hook)
    (remove-hook 'mu4e-view-mode-hook #'modeline-mu4e-view-hook))
  (boba-command "FWD" nil "Forward message"))

;; ═══════════════════════════════════════════════════════════════════════════
;; 7. Theme-reactive face colours
;; ═══════════════════════════════════════════════════════════════════════════

(defun boba-command--apply-faces ()
  "Derive boba-command faces from the active theme palette."
  (when (boundp 'theme-color-foreground)
    (set-face-attribute 'boba-command-face nil
                        :foreground theme-color-foreground
                        :background theme-color-subtle
                        :height     (face-attribute 'default :height nil 'default)
                        :box        nil)
    (set-face-attribute 'boba-command-prompt-face nil
                        :foreground theme-color-background
                        :background theme-color-foreground
                        :weight     'bold)
    (set-face-attribute 'boba-command-region-face nil
                        :foreground theme-color-foreground
                        :background theme-color-faded)
    (set-face-attribute 'boba-command-cursor-face nil
                        :foreground theme-color-background
                        :background theme-color-foreground)))

;; Apply once at load time, then re-apply after every theme refresh
(boba-command--apply-faces)
(with-eval-after-load 'ui/theme
  (advice-add 'theme-refresh :after #'boba-command--apply-faces))

;; ═══════════════════════════════════════════════════════════════════════════
;; 8. Keybindings
;; ═══════════════════════════════════════════════════════════════════════════

;; SPC ; — "quick command" prefix
;; Use after-init-hook + eval so macroexpansion is deferred past the point
;; where my-leader is defined (inside navigation/evil.el → general-create-definer).
;; A plain with-eval-after-load 'general fires too early — before my-leader exists.
(add-hook 'after-init-hook
          (lambda ()
            (eval
             '(when (fboundp 'my-leader)
                (my-leader
                  ";"     '(:ignore t               :which-key "Quick command")
                  "; x"   '(boba-command-x          :which-key "M-x via header-line")
                  "; !"   '(boba-command-shell       :which-key "Shell command (sync)")
                  "; &"   '(boba-command-async-shell :which-key "Shell command (async)")
                  "; c"   '(:ignore t               :which-key "Capture")
                  "; c t" '(boba-capture-todo        :which-key "Capture TODO")
                  "; c m" '(boba-capture-meeting     :which-key "Capture meeting")
                  "; c l" '(boba-capture-link        :which-key "Capture link"))))))

;;; Provide:
(provide 'ui/command)
(provide 'boba-command)
;;; command.el ends here
