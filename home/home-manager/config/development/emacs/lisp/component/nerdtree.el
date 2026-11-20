;;; nerdtree.el --- File tree explorer component using neotree -*- lexical-binding: t; -*-

;; Custom faces for a premium, muted aesthetic
;; (declare-function boba-sidebar-toggle "ui/sidebar")  ; disabled — using neotree native
(declare-function nerd-icons-octicon "nerd-icons")
(declare-function nerd-icons-icon-for-dir "nerd-icons")
(eval-when-compile
  (require 'navigation/evil nil t))

(defvar neo-window-width)
(defvar neo-smart-open)
(defvar neo-theme)
(defvar neo-mode-line-type)
(defvar neo-show-hidden-files)
(defvar neo-vc-integration)
(defvar neo-banner-message)
(defvar neo-keymap-style)
(defvar neo-show-updir-line)
(defvar neo-force-change-width)
(defface my-neo-folder-face nil
  "Face for neotree folder icons."
  :group 'neotree)

(defface my-neo-chevron-face nil
  "Face for neotree chevron icons."
  :group 'neotree)

(defface my-neo-dir-face nil
  "Face for neotree directory names."
  :group 'neotree)

(defface my-neo-file-face nil
  "Face for neotree file names."
  :group 'neotree)

(defun my-get-string-font-family (str)
  "Extract the font family from the face property of STR, if present."
  (let ((family (when (stringp str)
                  (let ((face (get-text-property 0 'face str)))
                    (cond
                     ((listp face)
                      (plist-get face :family))
                     ((facep face)
                      (let ((fam (face-attribute face :family)))
                        (unless (eq fam 'unspecified) fam)))
                     (t nil))))))
    (or family
        (and (boundp 'nerd-icons-font-family) nerd-icons-font-family)
        "Symbols Nerd Font Mono")))

(defun my-neo-sidebar-bg-is-light-p ()
  "Return t if the sidebar background colour (theme-color-subtle) is light."
  (let* ((bg  (or (and (boundp 'theme-color-subtle) theme-color-subtle)
                  ;; Fallback: read the remapped default face in this buffer
                  (face-background 'default nil t)))
         (rgb (when (and bg (not (string= bg "unspecified"))
                         (not (string= bg "unspecified-bg")))
                (color-name-to-rgb bg))))
    (if rgb
        (> (+ (* 0.2126 (nth 0 rgb))
              (* 0.7152 (nth 1 rgb))
              (* 0.0722 (nth 2 rgb)))
           0.5)
      nil)))

(defvar-local my-neo-face-remap-cookies nil
  "List of face remapping cookies in the neotree buffer.")

(defun my-neo-apply-colors-locally ()
  "Apply neotree face colors as buffer-local remaps.
  This runs inside the neotree buffer after the sidebar frame is live,
  so we can read the actual background-color and pick the right palette."
  (let* ((light (my-neo-sidebar-bg-is-light-p))
         ;; Pick palette based on actual sidebar background luminance
         (fg-dir  (if light "#1a202c" "#d8dce4"))
         (fg-file (if light "#2d3748" "#abb2bf"))
         (fg-chev (if light "#6b7280" "#5c6370"))
         (fg-icon (if light "#3d4455" "#9aa3b0"))
         (bg (or (and (boundp 'theme-color-subtle) theme-color-subtle)
                 (face-background 'default nil t))))
    ;; Clear previous remaps to avoid leaks
    (mapc #'face-remap-remove-relative my-neo-face-remap-cookies)
    (setq my-neo-face-remap-cookies nil)

    ;; Buffer-local face remaps — these take priority over global face attrs
    ;; and are scoped only to the neotree buffer.
    (dolist (remap
             (list
              (face-remap-add-relative 'neo-dir-link-face
                                       :foreground fg-dir :weight 'semi-bold)
              (face-remap-add-relative 'neo-file-link-face
                                       :foreground fg-file :weight 'normal)
              (face-remap-add-relative 'neo-expand-btn-face
                                       :foreground fg-chev :weight 'normal)
              (face-remap-add-relative 'neo-root-dir-face
                                       :foreground fg-dir :weight 'bold)
              (face-remap-add-relative 'my-neo-folder-face
                                       :foreground fg-icon :weight 'normal)
              (face-remap-add-relative 'my-neo-chevron-face
                                       :foreground fg-chev :weight 'normal)
              (face-remap-add-relative 'my-neo-dir-face
                                       :foreground fg-dir :weight 'semi-bold)
              (face-remap-add-relative 'my-neo-file-face
                                       :foreground fg-file :weight 'normal)))
      (push remap my-neo-face-remap-cookies))

    (when bg
      (push (face-remap-add-relative 'fringe
                                     :background bg :foreground bg)
            my-neo-face-remap-cookies)
      (push (face-remap-add-relative 'window-divider
                                     :foreground bg :background bg)
            my-neo-face-remap-cookies)
      (push (face-remap-add-relative 'window-divider-first-pixel
                                     :foreground bg :background bg)
            my-neo-face-remap-cookies)
      (push (face-remap-add-relative 'window-divider-last-pixel
                                     :foreground bg :background bg)
            my-neo-face-remap-cookies))))

;; Keep my-update-neotree-colors as a no-op alias for backwards compat
(defalias 'my-update-neotree-colors #'my-neo-apply-colors-locally)

;; Refresh buffer-local colors whenever the theme is toggled.
;; We find the live neotree buffer and re-apply colors inside it.
(defun my-neo-refresh-colors-on-theme-change ()
  "Re-apply neotree colors after a theme refresh."
  (when-let ((buf (get-buffer " *NeoTree*")))
    (with-current-buffer buf
      (my-neo-apply-colors-locally))))
(advice-add 'theme-refresh :after #'my-neo-refresh-colors-on-theme-change)

;; Redefine directory icon generator to use our custom faces
(defun my-neo-nerd-icons-icon-for-dir-with-chevron (dir &optional chevron padding)
  (ignore padding)
  (let* ((icon (nerd-icons-icon-for-dir dir))
         (family (my-get-string-font-family icon))
         (icon-char (if (stringp icon) (substring-no-properties icon) " "))
         (icon-with-face (propertize icon-char 'face `(:inherit my-neo-folder-face :family ,family)))
         (chev-icon (if chevron
                        (nerd-icons-octicon (format "nf-oct-chevron_%s" chevron)
                                            :height 0.8
                                            :v-adjust -0.1)
                      ""))
         (chev-family (my-get-string-font-family chev-icon))
         (chev-char (if (stringp chev-icon) (substring-no-properties chev-icon) ""))
         (chev-with-face (if (not (string-empty-p chev-char))
                             (propertize chev-char 'face `(:inherit my-neo-chevron-face :family ,chev-family))
                           "")))
    (concat chev-with-face " " icon-with-face " ")))

(defun my-neo-select-mru-window-advice (orig-fun arg)
  "Select parent frame's MRU window if in the sidebar child frame."
  (let* ((sidebar-p (frame-parameter nil 'sidebar-p))
         (parent (and sidebar-p (frame-parameter nil 'parent-frame))))
    (if parent
        (let ((win (get-mru-window parent)))
          (if win
              (select-window win)
            (funcall orig-fun arg)))
      (funcall orig-fun arg))))

(defun my-neo-ignore-resize-errors-advice (orig-fun &rest args)
  "Ignore window-resize or other errors during neotree sizing."
  (condition-case nil
      (apply orig-fun args)
    (error nil)))

(use-package neotree
  :commands (neotree-toggle neotree-show neotree-hide neotree-dir)
  :init
  ;; Bind F8 shortcut to toggle sidebar explorer
  (global-set-key [f8] #'neotree-toggle)
  :config
  ;; Custom settings to replicate the modern sidebar
  (setq neo-window-width 30
        neo-smart-open t
        neo-theme 'nerd-icons
        neo-mode-line-type 'none                    ; Hide modeline in neotree window
        neo-show-hidden-files t
        neo-vc-integration nil                      ; Keep it clean, no VC coloring
        neo-banner-message nil                      ; No banner text
        neo-keymap-style 'default
        neo-show-updir-line nil                     ; Clean root folder look
        neo-force-change-width t)

  (add-hook 'neotree-mode-hook
            (lambda ()
              ;; Remove header-line (don't want an extra bar)
              (setq-local header-line-format nil)
              ;; Disable line numbers
              (display-line-numbers-mode -1)
              ;; Left padding: 2-char left margin
              (setq left-margin-width 2)
              (set-window-margins (selected-window) 2 0)
              ;; Give the sidebar a distinct subtle background covering the
              ;; ENTIRE window top-to-bottom (buffer-face-mode fills empty
              ;; space too, unlike face-remap-add-relative which only affects
              ;; rendered text).
              (when (boundp 'theme-color-subtle)
                (setq-local buffer-face-mode-face
                            `(:background ,theme-color-subtle))
                (buffer-face-mode 1))
              ;; Disable cursor in the sidebar
              (setq cursor-type nil)
              (setq-local cursor-in-non-selected-windows nil)
              ;; Apply buffer-local color remaps (picks palette from background).
              (my-neo-apply-colors-locally)))

  ;; Add top padding by inserting blank lines after every buffer refresh
  (defun my-neo-add-top-padding (&rest _)
    "Insert blank lines at the top of the neotree buffer for visual padding."
    (when (eq major-mode 'neotree-mode)
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (insert "\n\n")))))

  (advice-add 'neo-buffer--refresh :after #'my-neo-add-top-padding)

  (advice-add 'neo--nerd-icons-icon-for-dir-with-chevron :override #'my-neo-nerd-icons-icon-for-dir-with-chevron)
  (advice-add 'neo-global--select-mru-window :around #'my-neo-select-mru-window-advice)
  (advice-add 'neo-util--set-window-width :around #'my-neo-ignore-resize-errors-advice)
  (advice-add 'neo-window--zoom :around #'my-neo-ignore-resize-errors-advice)
  (advice-add 'neo-global--set-window-width :around #'my-neo-ignore-resize-errors-advice))

(with-eval-after-load 'general
  (general-define-key
   :states '(normal insert visual motion)
   :keymaps 'override
   :prefix "SPC"
   :global-prefix "C-SPC"
   "t n" '(neotree-toggle :which-key "Toggle Sidebar Explorer")))

(provide 'component/nerdtree)
;;; nerdtree.el ends here
