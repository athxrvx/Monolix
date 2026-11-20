;;; modeline.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Lambda Line
(use-package lambda-line
  ;; :vc form pinned to Lambda-Emacs/lambda-line@0ca6b32 (the commit
  ;; that drops an unused all-the-icons require + Package-Requires
  ;; entry). Without this pin, a user running lambda-line on a host
  ;; without all-the-icons installed would crash at load time even
  ;; with the locate-library gate, because earlier commits of
  ;; lambda-line had an unconditional (require 'all-the-icons) at
  ;; top-level.
  ;;
  ;; Gate is on lem-load-extras only -- NOT (locate-library ...) --
  ;; because :when (keyword index 7) wraps :vc (index 8), and a
  ;; locate-library check would prevent the :vc install from running
  ;; on a fresh machine (chicken-and-egg). See Spec 02 post-review
  ;; finding P0-4 in AUDIT.md.
  :when lem-load-extras
  :vc (:url "https://github.com/Lambda-Emacs/lambda-line"
       :rev "0ca6b32")
  :custom
  (lambda-line-abbrev t)
  (lambda-line-position 'top)
  (lambda-line-hspace "  ")
  (lambda-line-prefix t)
  (lambda-line-prefix-padding nil)
  (lambda-line-status-invert nil)
  (lambda-line-gui-ro-symbol  " ⨂")  ;; ⬤◯⨂ⓧ
  (lambda-line-gui-mod-symbol " ⬤") ;; ⨀⬤ ◉
  (lambda-line-gui-rw-symbol  " ◯")  ;; ◉ ◎ ⬤◯
  (lambda-line-vc-symbol "⎇ ")  ;; Git branch symbol
  (lambda-line-space-top +.50)
  (lambda-line-space-bottom -.50)
  (lambda-line-symbol-position 0.1)
  (lambda-line-word-count-enabled t)
  :custom-face
  (lambda-line-visual-bell ((t (:background "red3"))))
  :config
  (lambda-line-mode)
  (lambda-line-visual-bell-config)
  ;; lem-setup-modeline runs before lem-setup-theme in the base
  ;; module batch, so `(lambda-line-mode)' caches its formats with
  ;; default faces -- before lambda-themes' face overrides have
  ;; been applied by the macOS system-appearance dispatch in
  ;; lem-setup-theme.el. On a daemon there's no frame redisplay
  ;; between the two events, so the first connecting client sees
  ;; the stale state (modeline at the bottom in default colours).
  ;; Re-toggle on every theme load -- including the initial system
  ;; apply and every macOS Light/Dark flip -- so the cache rebuilds
  ;; against the now-current theme.
  (add-hook 'lem-after-load-theme-hook
            (lambda ()
              (when (bound-and-true-p lambda-line-mode)
                (lambda-line-mode -1)
                (lambda-line-mode 1)))))

;;;; Evil State Indicator (Spec 06)
;; Integrates an evil state tag into lambda-line's composed modeline.
;; The tag is a fixed three-column field at the leading edge of the
;; modeline; populated labels are bold and carry a state-specific
;; background colour. Empty-case emits three spaces so toggling evil
;; mid-session does not shift adjacent segments.
;;
;; Why advice and not `evil-mode-line-format': lambda-line with
;; position 'top redirects its UI into header-line-format and stubs
;; mode-line-format to "%_". Any tag inserted via
;; `evil-mode-line-format' would land in the stubbed divider, not in
;; the visible lambda-line. See SPEC.md, "Alternative considered and
;; rejected".
;;
;; Palette is static -- no theme-reactive recompute. Tuned toward
;; saturated colours that remain readable on modus-operandi,
;; modus-vivendi, lambda-themes-dark, and lambda-themes-light. Users
;; on other themes may see contrast clashes; `defface' can be
;; remapped to override.

(defgroup lem-modeline nil
  "Lambda-emacs modeline extensions."
  :group 'lambda-line)

(with-eval-after-load 'evil
  ;; The `:box' on each face is given the same colour as the face's
  ;; `:background', so the tag carries a self-matched outline. This
  ;; matters now that `cpm/lambda-line-bump-contrast' puts a 1px box
  ;; on the `header-line' itself: without a box on the evil tag, the
  ;; coloured block reads as a notch in the strip outline. A
  ;; same-colour box keeps the tag visually contiguous with its own
  ;; fill while letting it sit flush inside the boxed strip.
  (defface lem-modeline-evil-normal
    '((t (:foreground "#62C554" :weight bold :background unspecified)))
    "Face for the evil normal-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-insert
    '((t (:foreground "#EC6A5E" :weight bold :background unspecified)))
    "Face for the evil insert-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-visual
    '((t (:foreground "#A3A3A3" :weight bold :background unspecified)))
    "Face for the evil visual-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-visual-line
    '((t (:foreground "#A3A3A3" :weight bold :background unspecified)))
    "Face for the evil visual-line-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-visual-block
    '((t (:foreground "#A3A3A3" :weight bold :background unspecified)))
    "Face for the evil visual-block-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-replace
    '((t (:foreground "#E67E22" :weight bold :background unspecified)))
    "Face for the evil replace-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-emacs
    '((t (:foreground "#81A1C1" :weight bold :background unspecified)))
    "Face for the evil emacs-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-motion
    '((t (:foreground "#F2DA61" :weight bold :background unspecified)))
    "Face for the evil motion-state tag in lambda-line."
    :group 'lem-modeline)

  (defface lem-modeline-evil-operator
    '((t (:foreground "#F2DA61" :weight bold :background unspecified)))
    "Face for the evil operator-state tag in lambda-line."
    :group 'lem-modeline)

  (defconst lem-modeline-evil--empty-tag "   "
    "Three-space field used when no evil state tag applies.
Width matches the populated labels so toggling evil mid-session
produces no column shift in surrounding modeline segments.")

  (defvar lem-modeline-evil--tag-alist nil
    "Alist mapping evil state symbols to pre-computed propertised tag
strings. Built once at install time under
`with-eval-after-load 'evil' and never recomputed on the redisplay
hot path.")

  ;; Padding convention: single-letter labels are centred within the
  ;; three-column field (one space on each side) so the letter sits in
  ;; the middle of the coloured background. Two-letter labels (VL, VB)
  ;; cannot be perfectly centred in three columns, so they are flushed
  ;; left with a trailing space; the visual effect is that the two
  ;; letters still occupy most of the block width. Width stays at
  ;; three columns across all labels and the empty case.
  (setq lem-modeline-evil--tag-alist
        (list (cons 'normal
                    (propertize " N " 'face 'lem-modeline-evil-normal))
              (cons 'insert
                    (propertize " I " 'face 'lem-modeline-evil-insert))
              (cons 'visual
                    (propertize " V " 'face 'lem-modeline-evil-visual))
              (cons 'visual-line
                    (propertize "VL " 'face 'lem-modeline-evil-visual-line))
              (cons 'visual-block
                    (propertize "VB " 'face 'lem-modeline-evil-visual-block))
              (cons 'replace
                    (propertize " R " 'face 'lem-modeline-evil-replace))
              (cons 'emacs
                    (propertize " E " 'face 'lem-modeline-evil-emacs))
              (cons 'motion
                    (propertize " M " 'face 'lem-modeline-evil-motion))
              (cons 'operator
                    (propertize " O " 'face 'lem-modeline-evil-operator))))

  (defun lem-modeline-evil-tag ()
    "Return the propertised tag for the current evil state.
Returns `lem-modeline-evil--empty-tag' (three spaces) in the empty
case: evil not loaded, no `evil-local-mode' in the current buffer,
`evil-state' nil, or the current state is not enumerated in
`lem-modeline-evil--tag-alist'.

When `evil-state' is `'visual', the visual sub-type is read from
`evil-visual-type' so that line-wise and block-wise visual
selections produce distinct tags (VL and VB respectively)."
    (or (and (bound-and-true-p evil-local-mode)
             (bound-and-true-p evil-state)
             (let ((key (if (and (eq evil-state 'visual)
                                 (bound-and-true-p evil-visual-type))
                            (pcase evil-visual-type
                              ('line  'visual-line)
                              ('block 'visual-block)
                              (_      'visual))
                          evil-state)))
               (cdr (assq key lem-modeline-evil--tag-alist))))
        lem-modeline-evil--empty-tag))

  (defun lem-modeline-evil--compose-advice (orig-fun status name
                                                     primary tertiary
                                                     secondary
                                                     &optional prefix)
    "Prepend the evil state tag to lambda-line's composed modeline.
ORIG-FUN is the original `lambda-line-compose'. Arguments STATUS,
NAME, PRIMARY, TERTIARY, SECONDARY, and PREFIX are passed through
unchanged. The tag is added to the leading edge so it sits before
lambda-line's status symbol and the rest of the modeline content."
    (let ((base (funcall orig-fun status name primary tertiary
                         secondary prefix))
          (tag (lem-modeline-evil-tag)))
      (if (stringp base)
          (concat tag base)
        base)))

  (advice-add 'lambda-line-compose :around
              #'lem-modeline-evil--compose-advice)

  ;; Shape-only evil state cursors. Values are symbols (or (shape . N)
  ;; cons cells) with no colour component: lambda-themes' palette,
  ;; when active, sets these variables with colour strings attached;
  ;; overriding them here ensures evil state transitions change only
  ;; cursor shape and never touch `cursor-color' or the OSC 12 path.
  ;; See SPEC.md cursor table and AC-7.
  ;;
  ;; Evil defines cursor variables only for its seven top-level states.
  ;; Visual-line and visual-block are sub-types of the visual state
  ;; (distinguished by `evil-visual-type'), not separate states, so
  ;; they inherit `evil-visual-state-cursor' automatically.
  (setq evil-normal-state-cursor   'box
        evil-insert-state-cursor   '(bar . 2)
        evil-visual-state-cursor   'box
        evil-replace-state-cursor  'hbar
        evil-emacs-state-cursor    'box
        evil-motion-state-cursor   'box
        evil-operator-state-cursor 'hollow))

;; TTY cursor shape. GUI emacs honours `cursor-type' natively;
;; terminal emacs has to emit DECSCUSR escape sequences to actually
;; change the cursor shape, and `evil-terminal-cursor-changer' does
;; that. Run only in TTY frames, and let `etcc-use-color' stay at its
;; default nil -- we want shape-only, no OSC 12.
;;
;; If the package is absent, emit a single `display-warning' at
;; startup and proceed. The evil state tag still renders; cursor
;; shape stays at whatever the terminal draws by default. This is a
;; distinct failure mode from "terminal does not honour DECSCUSR"
;; (see SPEC.md, "Integration-library missing" edge case).
(defvar lem-modeline-evil--etcc-warned nil
  "Non-nil once a display-warning about a missing
`evil-terminal-cursor-changer' has been emitted in this session.
Prevents the warning from firing on every frame creation.")

(defun lem-modeline-evil--maybe-activate-tty-cursor ()
  "In TTY frames, activate `evil-terminal-cursor-changer' for shape-only
DECSCUSR emission. If the package is absent, warn once per session."
  (when (and (not (display-graphic-p))
             (featurep 'evil))
    (if (require 'evil-terminal-cursor-changer nil t)
        (evil-terminal-cursor-changer-activate)
      (unless lem-modeline-evil--etcc-warned
        (setq lem-modeline-evil--etcc-warned t)
        (display-warning
         'lambda-emacs
         "evil-terminal-cursor-changer unavailable; TTY cursor shape \
will not track evil state. Install the package or ignore if the \
terminal does not honour DECSCUSR."
         :warning)))))

;; `tty-setup-hook' runs once per terminal initialisation: at startup
;; for a direct TTY boot, and at each `emacsclient -nw' connection for
;; a daemon. That covers every case where a TTY frame exists. The hook
;; never fires in `noninteractive' batch mode, so the boot-smoke tests
;; do not emit DECSCUSR sequences into the harness output.
(add-hook 'tty-setup-hook #'lem-modeline-evil--maybe-activate-tty-cursor)

;;;; Hide Modeline
(use-package hide-mode-line
  :when (and lem-load-extras (locate-library "hide-mode-line"))
  :commands hide-mode-line-mode)

;;; Provide:
(provide 'component/modeline)
;;; lem-setup-modeline.el ends here
