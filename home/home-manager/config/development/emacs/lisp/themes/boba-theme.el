;;; boba-theme.el --- Warm literary light theme -*- lexical-binding: t; -*-

(deftheme boba
  "A warm, elegant light theme inspired by Earl Grey and Aofuji.")

(let* ((fg       "#605A52") ; Tapioca
       (bg       "#FCFBF9") ; Milk Tea
       (bg-alt   "#F7F3EE") ; Foam

       (purple   "#83577D") ; Taro
       (blue     "#556995") ; Blueberry Tea
       (teal     "#477A7B") ; Jasmine Tea
       (orange   "#886A44") ; Brown Sugar
       (green    "#747B4D") ; Matcha
       (red      "#8F5652") ; Rose Tea

       (comment  "#A49C93")
       (border   "#E8E2DA")
       (region   "#E8DDE7")
       (current  "#F5F1EC")
       (strong   "#4A443C")) ; Dark Tapioca

  ;; Set the Nano/Atomic variables so the UI components match perfectly
  (setq frame-background-mode    'light)
  (setq theme-color-foreground   fg)
  (setq theme-color-background   bg)
  (setq theme-color-highlight    current)
  (setq theme-color-critical     red)
  (setq theme-color-salient      purple)
  (setq theme-color-strong       strong)
  (setq theme-color-popout       orange)
  (setq theme-color-subtle       bg-alt)
  (setq theme-color-faded        comment)
  (setq theme-color-modeline-bg  bg-alt)
  (setq theme-var "boba")

  (custom-theme-set-faces
   'boba

   ;; Base
   `(default ((t (:foreground ,fg :background ,bg))))
   `(cursor ((t (:background ,fg))))
   `(fringe ((t (:background ,bg))))
   `(shadow ((t (:foreground ,comment))))
   `(highlight ((t (:background ,bg-alt))))
   `(hl-line ((t (:background ,current))))
   `(region ((t (:background ,region))))
   `(secondary-selection ((t (:background ,bg-alt))))

   ;; Line numbers
   `(line-number
     ((t (:foreground "#B7ADA4" :background ,bg))))
   `(line-number-current-line
     ((t (:foreground ,purple :background ,bg :weight bold))))

   ;; Minibuffer
   `(minibuffer-prompt
     ((t (:foreground ,purple :weight bold))))

   ;; Links
   `(link
     ((t (:foreground ,teal :underline t))))
   `(link-visited
     ((t (:foreground ,purple :underline t))))

   ;; Search
   `(isearch
     ((t (:background ,orange
          :foreground ,bg
          :weight bold))))

   `(lazy-highlight
     ((t (:background "#E6DDD1"
          :foreground ,fg))))

   `(match
     ((t (:background "#E8DDE7"
          :foreground ,purple))))

   ;; Parentheses
   `(show-paren-match
     ((t (:background "#EEE7F0"
          :foreground ,purple
          :weight bold))))

   `(show-paren-mismatch
     ((t (:background ,red
          :foreground ,bg))))

   ;; Mode line
   `(mode-line
     ((t (:background ,bg-alt
          :foreground ,fg
          :height 0.1
          :box nil))))

   `(mode-line-inactive
     ((t (:background ,bg-alt
          :foreground ,comment
          :height 0.1
          :box nil))))

   `(modeline-active
     ((t (:background ,bg-alt
          :foreground ,fg
          :box (:line-width 1 :color ,bg-alt :style nil)))))

   `(modeline-inactive
     ((t (:background ,bg-alt
          :foreground ,comment
          :box (:line-width 1 :color ,bg-alt :style nil)))))

   `(modeline-status
     ((t (:foreground ,bg :background ,purple :weight bold))))

   ;; Header line
   `(header-line
     ((t (:background ,bg-alt
          :foreground ,fg
          :overline nil
          :underline nil
          :box (:line-width 4 :color ,bg-alt :style nil)
          :inherit nil))))

   ;; Vertical border
   `(vertical-border
     ((t (:foreground ,border))))

   ;; Font Lock

   ;; Comments
   `(font-lock-comment-face
     ((t (:foreground ,comment
          :slant italic))))

   `(font-lock-comment-delimiter-face
     ((t (:foreground ,comment
          :slant italic))))

   ;; Keywords
   `(font-lock-keyword-face
     ((t (:foreground ,red
          :weight semi-bold))))

   `(font-lock-builtin-face
     ((t (:foreground ,red))))

   ;; Types
   `(font-lock-type-face
     ((t (:foreground ,blue))))

   ;; Constants / Numbers
   `(font-lock-constant-face
     ((t (:foreground ,purple))))

   ;; Variables
   `(font-lock-variable-name-face
     ((t (:foreground ,fg))))

   ;; Functions
   `(font-lock-function-name-face
     ((t (:foreground ,green))))

   ;; Strings
   `(font-lock-string-face
     ((t (:foreground ,orange))))

   `(font-lock-doc-face
     ((t (:foreground ,orange))))

   ;; Warnings
   `(font-lock-warning-face
     ((t (:foreground ,red
          :weight bold))))

   ;; Preprocessor
   `(font-lock-preprocessor-face
     ((t (:foreground ,purple))))

   ;; Escape chars
   `(font-lock-escape-face
     ((t (:foreground ,purple))))

   ;; Success / warning / error
   `(success ((t (:foreground ,green))))
   `(warning ((t (:foreground ,orange))))
   `(error   ((t (:foreground ,red :weight bold))))

   ;; Buttons
   `(button
     ((t (:foreground ,purple
          :underline t))))

   ;; Completion
   `(completions-common-part
     ((t (:foreground ,purple
          :weight bold))))

   ;; Corfu
   `(corfu-default
     ((t (:background ,bg
          :foreground ,fg))))

   `(corfu-current
     ((t (:background "#EEE7F0"
          :foreground ,fg))))

   ;; Company
   `(company-tooltip
     ((t (:background ,bg-alt
          :foreground ,fg))))

   `(company-tooltip-selection
     ((t (:background "#EEE7F0"))))

   ;; Diff
   `(diff-added
     ((t (:foreground ,green))))

   `(diff-removed
     ((t (:foreground ,red))))

   `(diff-changed
     ((t (:foreground ,orange))))

   `(diff-refine-added
     ((t (:background "#DCE3D0"))))

   `(diff-refine-removed
     ((t (:background "#E8D7D5"))))

   ;; Org Mode
   `(org-document-title
     ((t (:foreground ,purple
          :weight bold
          :height 1.3))))

   `(org-level-1
     ((t (:foreground ,purple
          :weight bold
          :height 1.15))))

   `(org-level-2
     ((t (:foreground ,blue
          :weight bold))))

   `(org-level-3
     ((t (:foreground ,teal))))

   `(org-level-4
     ((t (:foreground ,green))))

   `(org-code
     ((t (:foreground ,orange :background ,bg-alt))))

   `(org-verbatim
     ((t (:foreground ,orange :background ,bg-alt))))

   `(org-block
     ((t (:background ,bg-alt :extend t))))

   `(org-quote
     ((t (:background ,bg-alt
          :slant italic))))

   ;; Markdown
   `(markdown-header-face-1
     ((t (:foreground ,purple
          :weight bold))))

   `(markdown-header-face-2
     ((t (:foreground ,blue
          :weight bold))))

   `(markdown-header-face-3
     ((t (:foreground ,teal))))

   `(markdown-link-face
     ((t (:foreground ,teal))))

   `(markdown-code-face
     ((t (:foreground ,orange :background ,bg-alt))))

   `(markdown-pre-face
     ((t (:background ,bg-alt))))

   ;; Magit
   `(magit-branch-local
     ((t (:foreground ,purple))))

   `(magit-branch-remote
     ((t (:foreground ,green))))

   `(magit-diff-added
     ((t (:foreground ,green))))

   `(magit-diff-removed
     ((t (:foreground ,red))))

   `(magit-section-heading
     ((t (:foreground ,purple
          :weight bold))))

   ;; Dashboard
   `(dashboard-button-face
     ((t (:foreground ,purple :weight bold :underline nil))))
   `(dashboard-border-face
     ((t (:foreground ,comment))))
   `(dashboard-title-face
     ((t (:foreground ,purple :weight bold))))

   ;; Vertico Posframe
   `(vertico-posframe
     ((t (:background ,bg-alt :foreground ,fg))))
   `(vertico-posframe-border
     ((t (:background ,border :foreground ,border))))

   ;; Terminal ANSI colors
   `(term-color-black   ((t (:foreground ,fg))))
   `(term-color-red     ((t (:foreground ,red))))
   `(term-color-green   ((t (:foreground ,green))))
   `(term-color-yellow  ((t (:foreground ,orange))))
   `(term-color-blue    ((t (:foreground ,blue))))
   `(term-color-magenta ((t (:foreground ,purple))))
   `(term-color-cyan    ((t (:foreground ,teal))))
   `(term-color-white   ((t (:foreground ,bg))))

   ;; ANSI
   `(ansi-color-black   ((t (:foreground ,fg))))
   `(ansi-color-red     ((t (:foreground ,red))))
   `(ansi-color-green   ((t (:foreground ,green))))
   `(ansi-color-yellow  ((t (:foreground ,orange))))
   `(ansi-color-blue    ((t (:foreground ,blue))))
   `(ansi-color-magenta ((t (:foreground ,purple))))
   `(ansi-color-cyan    ((t (:foreground ,teal))))
   `(ansi-color-white   ((t (:foreground ,bg))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'boba)

;;; boba-theme.el ends here
