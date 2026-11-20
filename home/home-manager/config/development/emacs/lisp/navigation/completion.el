;;; completion.el --- Completing read options -*- lexical-binding: t; -*-

;; Vertico for vertical interactive completion list
(use-package vertico
  :config
  (vertico-mode 1)
  (setq vertico-resize nil
        vertico-count 10
        vertico-cycle t))

(use-package vertico-posframe
  :after vertico
  :init
  (vertico-posframe-mode 1)
  :config
  (defun vertico-posframe-poshandler-vscode (info)
    "Position vertico-posframe at the top center of the frame, shifted down like VSCode."
    (let ((pos (posframe-poshandler-frame-top-center info)))
      (if pos
          (cons (car pos) (+ (cdr pos) 30))
        (cons 0 0))))
  (setq vertico-posframe-poshandler #'vertico-posframe-poshandler-vscode
        vertico-posframe-border-width 4
        vertico-posframe-width 100
        vertico-posframe-min-width 80
        vertico-posframe-height 12
        vertico-posframe-min-height 2)
  (defconst vertico-posframe-candidate-left-padding "  "
    "Extra space before completion icons inside the posframe.")

  (defconst vertico-posframe-candidate-vpad-height 0.22
    "Vertical padding (in line heights) above and below each candidate row.")

  (defun vertico-posframe--candidate-vpad ()
    "Display spec that adds balanced vertical padding inside a candidate row."
    (propertize " "
                'display `(space :height ,vertico-posframe-candidate-vpad-height)))

  (cl-defmethod vertico--format-candidate :around (cand prefix suffix index start
                                              &context ((vertico-posframe-mode-workable-p) (eql t)))
    (let ((vpad (vertico-posframe--candidate-vpad)))
      (cl-call-next-method cand
                           (concat vpad vertico-posframe-candidate-left-padding prefix)
                           (concat suffix vpad)
                           index start)))

  (setq vertico-posframe-parameters
        '((left-fringe . 16)
          (right-fringe . 16)
          (menu-bar-lines . 0)
          (tool-bar-lines . 0)
          (line-spacing . 0.12)
          (unsplittable . t)))

  (defun vertico-posframe--top-padding-header ()
    "Header line string that adds top padding inside the posframe."
    (propertize " " 'face `(:inherit vertico-posframe :height 1.0)))

  (defun vertico-posframe-minibuffer-setup ()
    "Setup minibuffer settings to polish vertico-posframe layout and styling."
    (when (and vertico-posframe-mode (posframe-workable-p))
      (setq-local fringe-indicator-alist nil)
      (setq-local header-line-format (vertico-posframe--top-padding-header))
      (setq-local mode-line-format nil)
      (let ((bg-color (face-attribute 'vertico-posframe :background nil t)))
        (when (or (null bg-color) (eq bg-color 'unspecified))
          (setq bg-color (face-background 'default)))
        (when bg-color
          (face-remap-add-relative 'fringe :background bg-color :foreground bg-color)))))

  (defun vertico-posframe--around-posframe-show (orig buffer-or-name &rest args)
    "Keep a top padding header line when showing the vertico posframe."
    (let ((buf (get-buffer buffer-or-name)))
      (when (and buf vertico-posframe-mode
                 (with-current-buffer buf (boundp 'vertico--input)))
        (unless (plist-member args :respect-header-line)
          (setq args (plist-put (copy-sequence args) :respect-header-line t)))
        (with-current-buffer buf
          (setq-local header-line-format (vertico-posframe--top-padding-header))))
      (apply orig buffer-or-name args)))

  (add-hook 'minibuffer-setup-hook #'vertico-posframe-minibuffer-setup)
  (advice-add 'posframe-show :around #'vertico-posframe--around-posframe-show))

;; Marginalia to add rich annotations to completion items
(use-package marginalia
  :config
  (marginalia-mode 1))

;; Orderless for fuzzy search queries
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion orderless)))
        read-file-name-completion-ignore-case t
        read-buffer-completion-ignore-case t
        completion-ignore-case t))

;; Consult for search, navigation and buffer switching
(use-package consult
  :bind (("C-s" . consult-line)
         ("M-y" . consult-yank-pop))
  :init
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format
        xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (setq consult-preview-key 'any
        consult-find-args "find . -not ( -path */.git -prune ) -not ( -path */.git/* -prune )"
        consult-fd-args '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
                          "--full-path --color=never --hidden --exclude .git")
        consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip --hidden --glob !.git/"))

(provide 'navigation/completion)
;;; completion.el ends here
