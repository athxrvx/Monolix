;;; theme.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'ui/faces)
(require 'ui/theme-light)
(require 'ui/theme-dark)
(require 'ui/theme-boba)

(defcustom theme-var nil
  "Variable which sets the default startup theme as light or dark.
Also allows for toggling of the themes. Is set to 'light' by
'theme-apply-light' and 'dark' by 'theme-apply-dark'.
Defaults to nil."
  :group 'theme
  :type 'string)

;; When we set a face, we take care of removing any previous settings
(defun set-face (face style)
  "Reset FACE and make it inherit STYLE."
  (if (facep face)
      (set-face-attribute face nil
                          :foreground 'unspecified :background 'unspecified
                          :family     'unspecified :slant      'unspecified
                          :weight     'unspecified :height     'unspecified
                          :underline  'unspecified :overline   'unspecified
                          :box        'unspecified :inherit    style)
    (message "Theme Warning: Face %s could not be set. It may not be defined."
             face)))
  


(defun theme--basics ()
  "Derive basic Emacs faces from theme-faces and theme-color-theme."

  (set-foreground-color theme-color-foreground)
  (set-background-color theme-color-background)

  ;; XXX the following seems to be a no-op, should it be removed?
  (set-face-attribute 'default nil
                      :foreground (face-foreground 'default)
                      :background (face-background 'default)
                      :weight     'light
                      :family     (face-attribute 'theme-face-default :family)
                      :height     (face-attribute 'theme-face-default :height))

  (if (display-graphic-p)
      (set-face-attribute 'bold nil :weight 'regular)
    (set-face-attribute 'bold nil :weight 'bold))

  ;; Structural
  (set-face 'bold                                     'theme-face-strong)
  (set-face 'italic                                    'theme-face-faded)
  (set-face 'bold-italic                              'theme-face-strong)
  (set-face 'region                                   'theme-face-subtle)
  (set-face 'highlight                                'theme-face-subtle)
  ;;(set-face 'fixed-pitch                                     'default)
  (set-face 'fixed-pitch-serif                       'theme-face-default)
  (set-face 'cursor                                  'theme-face-default)
  (if 'theme-font-family-proportional
      (set-face-attribute 'variable-pitch nil ;; to work with mixed-pitch
                :foreground (face-foreground 'default)
                :background (face-background 'default)
                :family     (face-attribute 'theme-face-variable-pitch :family)
                :height     (face-attribute 'theme-face-variable-pitch :height))
      (set-face 'variable-pitch                     'theme-face-default))

  (set-face-attribute 'cursor nil
                      :background (face-foreground 'theme-face-default))
  (set-face-attribute 'window-divider nil
                      :foreground (face-background 'theme-face-default))
  (set-face-attribute 'window-divider-first-pixel nil
                      :foreground theme-color-background)
  ;;                  :foreground (face-background 'theme-face-subtle))
  (set-face-attribute 'window-divider-last-pixel nil
                      :foreground theme-color-background)
  ;;                  :foreground (face-background 'theme-face-subtle)))
  (set-face-foreground 'vertical-border theme-color-subtle)

  ;; Semantic
  (set-face 'shadow                                    'theme-face-faded)
  (set-face 'success                                 'theme-face-salient)
  (set-face 'warning                                  'theme-face-popout)
  (set-face 'error                                  'theme-face-critical)
  (set-face 'match                                    'theme-face-popout)

  ;; General
  (set-face 'buffer-menu-buffer                       'theme-face-strong)
  (set-face 'minibuffer-prompt                        'theme-face-strong)
  (set-face 'link                                    'theme-face-salient)
  (set-face 'link-visited                            'theme-face-faded)
  (set-face 'button                                  'theme-face-strong)
  (set-face-attribute 'button nil :underline nil)
  (set-face 'fringe                                    'theme-face-faded)
  (set-face-attribute 'fringe nil
                      :foreground (face-background 'theme-face-subtle)
                      :background (face-background 'default))
  (set-face 'isearch                                  'theme-face-strong)
  (set-face 'isearch-fail                              'theme-face-faded)
  (set-face 'lazy-highlight                           'theme-face-subtle)
  (set-face 'trailing-whitespace                      'theme-face-subtle)
  (set-face 'show-paren-match                         'theme-face-popout)
  (set-face 'show-paren-mismatch                           'face-normal)
  (set-face-attribute 'tooltip nil                         :height 0.85)
  (set-face 'secondary-selection                      'theme-face-subtle)
  (set-face 'completions-common-part                   'theme-face-faded)
  (set-face 'completions-first-difference            'theme-face-default))
(defun theme-apply--font-lock ()
  "Derive font-lock faces from theme-faces."
  (set-face 'font-lock-comment-face                    'theme-face-faded)
  (set-face 'font-lock-doc-face                        'theme-face-faded)
  (set-face 'font-lock-string-face                    'theme-face-popout)
  (set-face 'font-lock-constant-face                 'theme-face-salient)
  (set-face 'font-lock-warning-face                   'theme-face-popout)
  (set-face 'font-lock-function-name-face             'theme-face-strong)
  (set-face 'font-lock-variable-name-face             'theme-face-strong)
  (set-face 'font-lock-builtin-face                  'theme-face-salient)
  (set-face 'font-lock-type-face                     'theme-face-salient)
  (set-face 'font-lock-keyword-face                  'theme-face-salient)
  
  ;; Emacs 29+ and Tree-sitter extra font-lock faces
  (when (facep 'font-lock-number-face)
    (set-face 'font-lock-number-face                   'theme-face-popout))
  (when (facep 'font-lock-operator-face)
    (set-face 'font-lock-operator-face                 'theme-face-strong))
  (when (facep 'font-lock-property-name-face)
    (set-face 'font-lock-property-name-face            'theme-face-strong))
  (when (facep 'font-lock-property-use-face)
    (set-face 'font-lock-property-use-face             'theme-face-strong))
  (when (facep 'font-lock-bracket-face)
    (set-face 'font-lock-bracket-face                  'theme-face-strong))
  (when (facep 'font-lock-delimiter-face)
    (set-face 'font-lock-delimiter-face                'theme-face-strong))
  (when (facep 'font-lock-escape-face)
    (set-face 'font-lock-escape-face                   'theme-face-popout))
  (when (facep 'font-lock-regexp-face)
    (set-face 'font-lock-regexp-face                   'theme-face-popout)))


(defun theme-apply--mode-line ()
  "Derive mode-line and header-line faces from theme-faces."
  (let ((bg-color (or theme-color-modeline-bg (face-background 'theme-face-default))))
    (set-face-attribute 'mode-line nil
                        :height 0.1
                        :foreground (if (display-graphic-p)
                                        (face-background 'theme-face-default)
                                      (face-foreground 'theme-face-default))
                        :background bg-color
                        :underline  (if (display-graphic-p)
                                        (face-background 'theme-face-subtle)
                                      t)
                        :overline nil
                        :box nil)
    (set-face-attribute 'mode-line-inactive nil
                        :height 0.1
                        :foreground (if (display-graphic-p)
                                        (face-background 'theme-face-default)
                                      (face-foreground 'theme-face-default))
                        :background bg-color
                        :underline (if (display-graphic-p)
                                       (face-background 'theme-face-subtle)
                                     t)
                        :overline nil
                        :inherit nil
                        :box nil)
    (when (facep 'modeline-active)
      (set-face-attribute 'modeline-active nil
                          :background bg-color
                          :foreground theme-color-foreground
                          :box `(:line-width 6 :color ,bg-color :style nil)))
    (when (facep 'modeline-inactive)
      (set-face-attribute 'modeline-inactive nil
                          :background bg-color
                          :foreground theme-color-faded
                          :box `(:line-width 6 :color ,bg-color :style nil))))
  
  ;;(when (display-graphic-p)
  (set-face-attribute 'header-line nil
                       :weight 'regular
                       :foreground (face-foreground 'theme-face-default)
                       :background (face-background 'theme-face-subtle)
                       :overline nil
                       :underline nil
                       :box `(:line-width 4
                                          :color ,(face-background 'theme-face-subtle)
                                          :style nil)
                       :inherit nil)

  ;; (when (not (display-graphic-p))
  ;;   (set-face-attribute 'header-line nil
  ;;                    :weight 'light
  ;;                       :foreground (face-foreground 'theme-face-default)
  ;;                       :background (face-background 'theme-face-subtle)
  ;;                       :inverse-video t
  ;;                       :overline nil
  ;;                       :underline nil
  ;;                       :box nil
  ;;                            :inherit nil))

  ;; (set-face-attribute 'internal-border nil
  ;;                     :background (face-foreground 'theme-face-default))

  (set-face-attribute 'internal-border nil
                       :background (face-background 'theme-face-default)))


(defun theme-apply--minibuffer ()
  "Derive minibuffer / echo area faces from nano faces."
  ;; Minibuffer / echo area
  (dolist (buffer (list " *Minibuf-0*" " *Echo Area 0*"
                        " *Minibuf-1*" " *Echo Area 1*"))
    (when (get-buffer buffer)
      (with-current-buffer buffer
        (face-remap-add-relative 'default 'theme-face-faded)))))


(defun theme-apply--hl-line ()
  "Derive hl-line faces from nano faces."
  (with-eval-after-load 'hl-line
    (set-face-attribute 'hl-line nil
                         :background theme-color-highlight)))



(defun theme-apply--buttons ()
  "Derive button faces from nano faces."
  ;; Buttons
  (with-eval-after-load 'cus-edit
    (set-face-attribute 'custom-button nil
                         :foreground (face-foreground 'theme-face-faded)
                         :background (face-background 'theme-face-default)
                         :box `(:line-width 1
                                :color ,(face-foreground 'theme-face-faded)
                                :style nil))
    (set-face-attribute 'custom-button-mouse nil
                         ;;                      :inherit 'custom-button
                         :foreground (face-foreground 'theme-face-faded)
                         :background (face-background 'theme-face-subtle)
                         :box `(:line-width 1
                                            :color ,(face-foreground 'theme-face-faded)
                                            :style nil))
    (set-face-attribute 'custom-button-pressed nil
                         :foreground (face-background 'default)
                         :background (face-foreground 'theme-face-salient)
                         :inherit 'theme-face-salient
                         :box `(:line-width 1
                                            :color ,(face-foreground 'theme-face-salient)
                                            :style nil)
                         :inverse-video nil)))


(defun theme-apply--info ()
  "Derive info faces from nano faces."
  (with-eval-after-load 'info
    (set-face 'info-menu-header                       'theme-face-strong)
    (set-face 'info-header-node                      'theme-face-default)
    (set-face 'info-index-match                      'theme-face-salient)
    (set-face 'Info-quoted                             'theme-face-faded)
    (set-face 'info-title-1                           'theme-face-strong)
    (set-face 'info-title-2                           'theme-face-strong)
    (set-face 'info-title-3                           'theme-face-strong)
    (set-face 'info-title-4                           'theme-face-strong)))


(defun theme-apply--speedbar ()
  "Derive speedbar faces from nano faces "
  (with-eval-after-load 'speedbar
    (set-face 'speedbar-button-face                    'theme-face-faded)
    (set-face 'speedbar-directory-face                'theme-face-strong)
    (set-face 'speedbar-file-face                    'theme-face-default)
    (set-face 'speedbar-highlight-face             'theme-face-highlight)
    (set-face 'speedbar-selected-face                 'theme-face-subtle)
    (set-face 'speedbar-separator-face                 'theme-face-faded)
    (set-face 'speedbar-tag-face                       'theme-face-faded)))


(defun theme-apply--bookmark ()
  "Derive bookmark faces from nano faces."
  (with-eval-after-load 'bookmark
    (set-face 'bookmark-menu-heading                  'theme-face-strong)
    (set-face 'bookmark-menu-bookmark                'theme-face-salient)))


(defun theme-apply--message ()
  "Derive message faces from nano faces."
  (with-eval-after-load 'message
    (unless (version< emacs-version "27.0")
      (set-face 'message-cited-text-1                  'theme-face-faded)
      (set-face 'message-cited-text-2                  'theme-face-faded)
      (set-face 'message-cited-text-3                  'theme-face-faded)
      (set-face 'message-cited-text-4                 'theme-face-faded))
    (set-face 'message-cited-text                      'theme-face-faded)
    (set-face 'message-header-cc                     'theme-face-default)
    (set-face 'message-header-name                    'theme-face-strong)
    (set-face 'message-header-newsgroups             'theme-face-default)
    (set-face 'message-header-other                  'theme-face-default)
    (set-face 'message-header-subject                'theme-face-salient)
    (set-face 'message-header-to                     'theme-face-salient)
    (set-face 'message-header-xheader                'theme-face-default)
    (set-face 'message-mml                            'theme-face-popout)
    (set-face 'message-separator                       'theme-face-faded)))


(defun theme-apply--outline ()
  "Derive outline faces from nano faces."
  (with-eval-after-load 'outline
    (set-face 'outline-1                              'theme-face-strong)
    (set-face 'outline-2                              'theme-face-strong)
    (set-face 'outline-3                              'theme-face-strong)
    (set-face 'outline-4                              'theme-face-strong)
    (set-face 'outline-5                              'theme-face-strong)
    (set-face 'outline-6                              'theme-face-strong)
    (set-face 'outline-7                              'theme-face-strong)
    (set-face 'outline-8                              'theme-face-strong)))


(defun theme-apply--customize ()
  "Derive customize faces from nano faces."
  (with-eval-after-load 'cus-edit
    (set-face 'widget-field                           'theme-face-subtle)
    (set-face 'widget-button                          'theme-face-strong)
    (set-face 'widget-single-line-field               'theme-face-subtle)
    (set-face 'custom-group-subtitle                  'theme-face-strong)
    (set-face 'custom-group-tag                       'theme-face-strong)
    (set-face 'custom-group-tag-1                     'theme-face-strong)
    (set-face 'custom-comment                          'theme-face-faded)
    (set-face 'custom-comment-tag                      'theme-face-faded)
    (set-face 'custom-changed                        'theme-face-salient)
    (set-face 'custom-modified                       'theme-face-salient)
    (set-face 'custom-face-tag                        'theme-face-strong)
    (set-face 'custom-variable-tag                    'theme-face-strong)
    (set-face 'custom-invalid                         'theme-face-popout)
    (set-face 'custom-visibility                     'theme-face-salient)
    (set-face 'custom-state                          'theme-face-salient)
    (set-face 'custom-link                           'theme-face-salient)))

(defun theme-apply--package ()
  "Derive package faces from nano faces."
  (with-eval-after-load 'package
    (set-face 'package-description                   'theme-face-default)
    (set-face 'package-help-section-name             'theme-face-default)
    (set-face 'package-name                          'theme-face-salient)
    (set-face 'package-status-avail-obso               'theme-face-faded)
    (set-face 'package-status-available              'theme-face-default)
    (set-face 'package-status-built-in               'theme-face-salient)
    (set-face 'package-status-dependency             'theme-face-salient)
    (set-face 'package-status-disabled                 'theme-face-faded)
    (set-face 'package-status-external               'theme-face-default)
    (set-face 'package-status-held                   'theme-face-default)
    (set-face 'package-status-incompat                 'theme-face-faded)
    (set-face 'package-status-installed              'theme-face-salient)
    (set-face 'package-status-new                    'theme-face-default)
    (set-face 'package-status-unsigned               'theme-face-default))

  ;; Button face is hardcoded, we have to redefine the relevant
  ;; function
  (defun package-make-button (text &rest properties)
    "Insert button labeled TEXT with button PROPERTIES at point.
PROPERTIES are passed to `insert-text-button', for which this
function is a convenience wrapper used by `describe-package-1'."
    (let ((button-text (if (display-graphic-p)
                           text (concat "[" text "]")))
          (button-face (if (display-graphic-p)
                           `(:box `(:line-width 1
                                    :color ,theme-color-subtle
                                    :style nil)
                                  :foreground ,theme-color-faded
                                  :background ,theme-color-subtle)
                         'link)))
      (apply #'insert-text-button button-text
               'face button-face 'follow-link t properties))))


(defun theme-apply--flyspell ()
  "Derive flyspell faces from nano faces."
  (with-eval-after-load 'flyspell
    (set-face 'flyspell-duplicate                     'theme-face-popout)
    (set-face 'flyspell-incorrect                     'theme-face-popout)))


(defun theme-apply--ido ()
  "Derive ido faces from nano faces."
  (with-eval-after-load 'ido
    (set-face 'ido-first-match                       'theme-face-salient)
    (set-face 'ido-only-match                          'theme-face-faded)
    (set-face 'ido-subdir                             'theme-face-strong)))


(defun theme-apply--diff ()
  "Derive diff faces from nano faces."
  (with-eval-after-load 'diff-mode
    (set-face 'diff-header                             'theme-face-faded)
    (set-face 'diff-file-header                       'theme-face-strong)
    (set-face 'diff-context                          'theme-face-default)
    (set-face 'diff-removed                            'theme-face-faded)
    (set-face 'diff-changed                           'theme-face-popout)
    (set-face 'diff-added                            'theme-face-salient)
    (set-face 'diff-refine-added                    '(theme-face-salient
                                                      theme-face-strong))
    (set-face 'diff-refine-changed                    'theme-face-popout)
    (set-face 'diff-refine-removed                    'theme-face-faded)
    (set-face-attribute     'diff-refine-removed nil :strike-through t)))


(defun theme-apply--term ()
  "Derive term faces from nano faces, and material theme colors."
  (with-eval-after-load 'term
    ;; (setq eterm-256color-disable-bold nil)
    (set-face 'term-bold                                   'theme-face-strong)
    (set-face-attribute 'term-color-black nil
                         :foreground (face-foreground 'theme-face-default)
                         :background (face-foreground 'theme-face-default))
    (set-face-attribute 'term-color-white nil
                         :foreground (face-background 'theme-face-default)
                         :background (face-background 'theme-face-default))
    (set-face-attribute 'term-color-blue nil
                         :foreground "#42A5F5"   ;; material color blue L400
                         :background "#BBDEFB")  ;; material color blue L100
    (set-face-attribute 'term-color-cyan nil
                         :foreground "#26C6DA"   ;; material color cyan L400
                         :background "#B2EBF2")  ;; material color cyan L100
    (set-face-attribute 'term-color-green nil
                         :foreground "#66BB6A"   ;; material color green L400
                         :background "#C8E6C9")  ;; material color green L100
    (set-face-attribute 'term-color-magenta nil
                         :foreground "#AB47BC"   ;; material color purple L400
                         :background "#E1BEE7")  ;; material color purple L100
    (set-face-attribute 'term-color-red nil
                         :foreground "#EF5350"   ;; material color red L400
                         :background "#FFCDD2")  ;; material color red L100
    (set-face-attribute 'term-color-yellow nil
                         :foreground "#FFEE58"    ;; material color yellow L400
                         :background "#FFF9C4"))) ;; material color yellow L100


(defun theme-apply--calendar ()
  "Derive calendar faces from nano faces."
  (with-eval-after-load 'calendar
    (set-face 'calendar-today                         'theme-face-strong)))


(defun theme-apply--agenda ()
  "Derive agenda faces from nano faces."
  (with-eval-after-load 'org-agenda
    (set-face 'org-agenda-calendar-event             'theme-face-default)
    (set-face 'org-agenda-calendar-sexp              'theme-face-salient)
    (set-face 'org-agenda-clocking                     'theme-face-faded)
    (set-face 'org-agenda-column-dateline              'theme-face-faded)
    (set-face 'org-agenda-current-time                'theme-face-strong)
    (set-face 'org-agenda-date                       'theme-face-salient)
    (set-face 'org-agenda-date-today                '(theme-face-salient
                                                       theme-face-strong))
    (set-face 'org-agenda-date-weekend                 'theme-face-faded)
    (set-face 'org-agenda-diary                        'theme-face-faded)
    (set-face 'org-agenda-dimmed-todo-face             'theme-face-faded)
    (set-face 'org-agenda-done                         'theme-face-faded)
    (set-face 'org-agenda-filter-category              'theme-face-faded)
    (set-face 'org-agenda-filter-effort                'theme-face-faded)
    (set-face 'org-agenda-filter-regexp                'theme-face-faded)
    (set-face 'org-agenda-filter-tags                  'theme-face-faded)
    ;;  (set-face 'org-agenda-property-face                'theme-face-faded)
    (set-face 'org-agenda-restriction-lock             'theme-face-faded)
    (set-face 'org-agenda-structure                   'theme-face-strong)))


(defun theme-apply--org ()
  "Derive org faces from nano faces."
  (with-eval-after-load 'org
    (set-face 'org-archived                            'theme-face-faded)

    (set-face 'org-block                                       'hl-line)
    (set-face 'org-block-begin-line                    'theme-face-faded)
    (set-face 'org-block-end-line                      'theme-face-faded)
    (unless (version< emacs-version "27.0")
      (set-face-attribute 'org-block nil                      :extend t)
      (set-face-attribute 'org-block-begin-line nil           :extend t)
      (set-face-attribute 'org-block-end-line nil             :extend t))

    (set-face 'org-checkbox                            'theme-face-faded)
    (set-face 'org-checkbox-statistics-done            'theme-face-faded)
    (set-face 'org-checkbox-statistics-todo            'theme-face-faded)
    (set-face 'org-clock-overlay                       'theme-face-faded)
    (set-face 'org-code                                'theme-face-faded)
    (set-face 'org-column                              'theme-face-faded)
    (set-face 'org-column-title                        'theme-face-faded)
    (set-face 'org-date                                'theme-face-faded)
    (set-face 'org-date-selected                       'theme-face-faded)
    (set-face 'org-default                             'theme-face-faded)
    (set-face 'org-document-info                       'theme-face-faded)
    (set-face 'org-document-info-keyword               'theme-face-faded)
    (set-face 'org-document-title                      'theme-face-faded)
    (set-face 'org-done                              'theme-face-default)
    (set-face 'org-drawer                              'theme-face-faded)
    (set-face 'org-ellipsis                            'theme-face-faded)
    (set-face 'org-footnote                            'theme-face-faded)
    (set-face 'org-formula                             'theme-face-faded)
    (set-face 'org-headline-done                       'theme-face-faded)
    ;; (set-face 'org-hide                             'theme-face-faded)
    ;; (set-face 'org-indent                           'theme-face-faded)
    (set-face 'org-latex-and-related                   'theme-face-faded)
    (set-face 'org-level-1                            'theme-face-strong)
    (set-face 'org-level-2                            'theme-face-strong)
    (set-face 'org-level-3                            'theme-face-strong)
    (set-face 'org-level-4                            'theme-face-strong)
    (set-face 'org-level-5                            'theme-face-strong)
    (set-face 'org-level-6                            'theme-face-strong)
    (set-face 'org-level-7                            'theme-face-strong)
    (set-face 'org-level-8                            'theme-face-strong)
    (set-face 'org-link                              'theme-face-salient)
    (set-face 'org-list-dt                             'theme-face-faded)
    (set-face 'org-macro                               'theme-face-faded)
    (set-face 'org-meta-line                           'theme-face-faded)
    (set-face 'org-mode-line-clock                     'theme-face-faded)
    (set-face 'org-mode-line-clock-overrun             'theme-face-faded)
    (set-face 'org-priority                            'theme-face-faded)
    (set-face 'org-property-value                      'theme-face-faded)
    (set-face 'org-quote                               'theme-face-faded)
    (set-face 'org-scheduled                           'theme-face-faded)
    (set-face 'org-scheduled-previously                'theme-face-faded)
    (set-face 'org-scheduled-today                   '(theme-face-salient
+                                                      theme-face-strong))
    (set-face 'org-sexp-date                           'theme-face-faded)
    (set-face 'org-special-keyword                     'theme-face-faded)
    (set-face 'org-table                               'theme-face-faded)
    (set-face 'org-tag                                'theme-face-popout)
    (set-face 'org-tag-group                           'theme-face-faded)
    (set-face 'org-target                              'theme-face-faded)
    (set-face 'org-time-grid                           'theme-face-faded)
    (set-face 'org-todo                              'theme-face-salient)
    (set-face 'org-upcoming-deadline                 'theme-face-default)
    (set-face 'org-verbatim                           'theme-face-popout)
    (set-face 'org-verse                               'theme-face-faded)
    (set-face 'org-warning                            'theme-face-popout)))


(defun theme-apply--mu4e ()
  "Derive mu4e faces from nano faces."
  (with-eval-after-load 'mu4e
    (set-face 'mu4e-attach-number-face                'theme-face-strong)
    (set-face 'mu4e-cited-1-face                       'theme-face-faded)
    (set-face 'mu4e-cited-2-face                       'theme-face-faded)
    (set-face 'mu4e-cited-3-face                       'theme-face-faded)
    (set-face 'mu4e-cited-4-face                       'theme-face-faded)
    (set-face 'mu4e-cited-5-face                       'theme-face-faded)
    (set-face 'mu4e-cited-6-face                       'theme-face-faded)
    (set-face 'mu4e-cited-7-face                       'theme-face-faded)
    (set-face 'mu4e-compose-header-face                'theme-face-faded)
    (set-face 'mu4e-compose-separator-face             'theme-face-faded)
    (set-face 'mu4e-contact-face                     'theme-face-salient)
    (set-face 'mu4e-context-face                       'theme-face-faded)
    (set-face 'mu4e-draft-face                         'theme-face-faded)
    (set-face 'mu4e-flagged-face                      'theme-face-popout)
    (set-face 'mu4e-footer-face                        'theme-face-faded)
    (set-face 'mu4e-forwarded-face                   'theme-face-default)
    (set-face 'mu4e-header-face                      'theme-face-default)
    (set-face 'mu4e-header-highlight-face                      'hl-line)
    (set-face 'mu4e-header-key-face                   'theme-face-strong)
    (set-face 'mu4e-header-marks-face                  'theme-face-faded)
    (set-face 'mu4e-header-title-face                 'theme-face-strong)
    (set-face 'mu4e-header-value-face                'theme-face-default)
    (set-face 'mu4e-highlight-face                    'theme-face-popout)
    (set-face 'mu4e-link-face                        'theme-face-salient)
    (set-face 'mu4e-modeline-face                      'theme-face-faded)
    (set-face 'mu4e-moved-face                         'theme-face-faded)
    (set-face 'mu4e-ok-face                            'theme-face-faded)
    (set-face 'mu4e-region-code                        'theme-face-faded)
    (set-face 'mu4e-replied-face                     'theme-face-default)
    (set-face 'mu4e-special-header-value-face        'theme-face-default)
    (set-face 'mu4e-system-face                        'theme-face-faded)
    (set-face 'mu4e-title-face                        'theme-face-strong)
    (set-face 'mu4e-trashed-face                       'theme-face-faded)
    (set-face 'mu4e-unread-face                       'theme-face-strong)
    ;;(set-face-attribute 'mu4e-unread-face nil :weight 'regular)
    (set-face 'mu4e-url-number-face                    'theme-face-faded)
    (set-face 'mu4e-view-body-face                   'theme-face-default)
    (set-face 'mu4e-warning-face                      'theme-face-popout)))


(defun theme-apply--elfeed ()
  "Derive elfeed faces from nano faces."
  (with-eval-after-load 'elfeed
    (set-face 'elfeed-log-date-face                    'theme-face-faded)
    (set-face 'elfeed-log-info-level-face            'theme-face-default)
    (set-face 'elfeed-log-debug-level-face           'theme-face-default)
    (set-face 'elfeed-log-warn-level-face             'theme-face-popout)
    (set-face 'elfeed-log-error-level-face            'theme-face-popout)
    (set-face 'elfeed-search-tag-face                  'theme-face-faded)
    (set-face 'elfeed-search-date-face                 'theme-face-faded)
    (set-face 'elfeed-search-feed-face               'theme-face-salient)
    (set-face 'elfeed-search-filter-face               'theme-face-faded)
    (set-face 'elfeed-search-last-update-face        'theme-face-salient)
    (set-face 'elfeed-search-title-face              'theme-face-default)
    (set-face 'elfeed-search-tag-face                  'theme-face-faded)
    (set-face 'elfeed-search-unread-count-face        'theme-face-strong)
    (set-face 'elfeed-search-unread-title-face        'theme-face-strong)))

(defun theme-apply--deft ()
  "Derive deft faces from nano faces."
  (with-eval-after-load 'deft
    (set-face 'deft-filter-string-error-face         'theme-face-popout)
    (set-face 'deft-filter-string-face              'theme-face-default)
    (set-face 'deft-header-face                     'theme-face-salient)
    (set-face 'deft-separator-face                    'theme-face-faded)
    (set-face 'deft-summary-face                      'theme-face-faded)
    (set-face 'deft-time-face                       'theme-face-salient)
    (set-face 'deft-title-face                       'theme-face-strong)))

(defun theme-apply--rst ()
  "Derive rst faces from nano faces."
  (with-eval-after-load 'rst
    (set-face 'rst-adornment                           'theme-face-faded)
    (set-face 'rst-block                             'theme-face-default)
    (set-face 'rst-comment                             'theme-face-faded)
    (set-face 'rst-definition                        'theme-face-salient)
    (set-face 'rst-directive                         'theme-face-salient)
    (set-face 'rst-emphasis1                           'theme-face-faded)
    (set-face 'rst-emphasis2                          'theme-face-strong)
    (set-face 'rst-external                          'theme-face-salient)
    (set-face 'rst-level-1                            'theme-face-strong)
    (set-face 'rst-level-2                            'theme-face-strong)
    (set-face 'rst-level-3                            'theme-face-strong)
    (set-face 'rst-level-4                            'theme-face-strong)
    (set-face 'rst-level-5                            'theme-face-strong)
    (set-face 'rst-level-6                            'theme-face-strong)
    (set-face 'rst-literal                           'theme-face-salient)
    (set-face 'rst-reference                         'theme-face-salient)
    (set-face 'rst-transition                        'theme-face-default)))


(defun theme-apply--markdown ()
  "Derive markdown faces from nano faces."
  (with-eval-after-load 'markdown-mode
    (set-face 'markdown-blockquote-face              'theme-face-default)
    (set-face 'markdown-bold-face                     'theme-face-strong)
    (set-face 'markdown-code-face                    'theme-face-default)
    (set-face 'markdown-comment-face                   'theme-face-faded)
    (set-face 'markdown-footnote-marker-face         'theme-face-default)
    (set-face 'markdown-footnote-text-face           'theme-face-default)
    (set-face 'markdown-gfm-checkbox-face            'theme-face-default)
    (set-face 'markdown-header-delimiter-face          'theme-face-faded)
    (set-face 'markdown-header-face                   'theme-face-strong)
    (set-face 'markdown-header-face-1                 'theme-face-strong)
    (set-face 'markdown-header-face-2                 'theme-face-strong)
    (set-face 'markdown-header-face-3                 'theme-face-strong)
    (set-face 'markdown-header-face-4                 'theme-face-strong)
    (set-face 'markdown-header-face-5                 'theme-face-strong)
    (set-face 'markdown-header-face-6                'theme-face-strong)
    (set-face 'markdown-header-rule-face             'theme-face-default)
    (set-face 'markdown-highlight-face               'theme-face-default)
    (set-face 'markdown-hr-face                      'theme-face-default)
    (set-face 'markdown-html-attr-name-face          'theme-face-default)
    (set-face 'markdown-html-attr-value-face         'theme-face-default)
    (set-face 'markdown-html-entity-face             'theme-face-default)
    (set-face 'markdown-html-tag-delimiter-face      'theme-face-default)
    (set-face 'markdown-html-tag-name-face           'theme-face-default)
    (set-face 'markdown-inline-code-face              'theme-face-popout)
    (set-face 'markdown-italic-face                    'theme-face-faded)
    (set-face 'markdown-language-info-face           'theme-face-default)
    (set-face 'markdown-language-keyword-face        'theme-face-default)
    (set-face 'markdown-line-break-face              'theme-face-default)
    (set-face 'markdown-link-face                    'theme-face-salient)
    (set-face 'markdown-link-title-face              'theme-face-default)
    (set-face 'markdown-list-face                      'theme-face-faded)
    (set-face 'markdown-markup-face                    'theme-face-faded)
    (set-face 'markdown-math-face                    'theme-face-default)
    (set-face 'markdown-metadata-key-face              'theme-face-faded)
    (set-face 'markdown-metadata-value-face            'theme-face-faded)
    (set-face 'markdown-missing-link-face            'theme-face-default)
    (set-face 'markdown-plain-url-face               'theme-face-default)
    (set-face 'markdown-pre-face                     'theme-face-default)
    (set-face 'markdown-reference-face               'theme-face-salient)
    (set-face 'markdown-strike-through-face            'theme-face-faded)
    (set-face 'markdown-table-face                   'theme-face-default)
    (set-face 'markdown-url-face                     'theme-face-salient)))


(defun theme-apply--ivy ()
  "Derive ivy faces from nano faces."
  (with-eval-after-load 'ivy
    (set-face 'ivy-action                              'theme-face-faded)
    (set-face 'ivy-completions-annotations             'theme-face-faded)
    (set-face 'ivy-confirm-face                        'theme-face-faded)
    (set-face 'ivy-current-match    '(theme-face-strong theme-face-subtle))
    (set-face 'ivy-cursor                             'theme-face-strong)
    (set-face 'ivy-grep-info                          'theme-face-strong)
    (set-face 'ivy-grep-line-number                    'theme-face-faded)
    (set-face 'ivy-highlight-face                     'theme-face-strong)
    (set-face 'ivy-match-required-face                 'theme-face-faded)
    (set-face 'ivy-minibuffer-match-face-1             'theme-face-faded)
    (set-face 'ivy-minibuffer-match-face-2             'theme-face-faded)
    (set-face 'ivy-minibuffer-match-face-3             'theme-face-faded)
    (set-face 'ivy-minibuffer-match-face-4             'theme-face-faded)
    (set-face 'ivy-minibuffer-match-highlight         'theme-face-strong)
    (set-face 'ivy-modified-buffer                    'theme-face-popout)
    (set-face 'ivy-modified-outside-buffer            'theme-face-strong)
    (set-face 'ivy-org                                 'theme-face-faded)
    (set-face 'ivy-prompt-match                        'theme-face-faded)
    (set-face 'ivy-remote                            'theme-face-default)
    (set-face 'ivy-separator                           'theme-face-faded)
    (set-face 'ivy-subdir                              'theme-face-faded)
    (set-face 'ivy-virtual                             'theme-face-faded)
    (set-face 'ivy-yanked-word                         'theme-face-faded)))

(defun theme-apply--helm ()
  "Derive helm faces from nano faces."
  (with-eval-after-load 'helm
    (set-face 'helm-selection                '(theme-face-strong theme-face-subtle))
    (set-face 'helm-match                                       'theme-face-strong)
    (set-face 'helm-source-header                              'theme-face-salient)
    (set-face 'helm-visible-mark                                'theme-face-strong)))

(defun theme-apply--helm-swoop ()
  "Derive helm faces from nano faces."
  (with-eval-after-load 'helm-swoop
    (set-face 'helm-swoop-target-line-face   '(theme-face-strong theme-face-subtle))))

(defun theme-apply--helm-occur ()
  "Derive helm faces from nano faces."
  (with-eval-after-load 'helm-occur
    (set-face 'helm-moccur-buffer                               'theme-face-strong)))

(defun theme-apply--helm-ff ()
  "Derive helm faces from nano faces."
  (with-eval-after-load 'helm-ff
    (set-face 'helm-ff-file                                      'theme-face-faded)
    (set-face 'helm-ff-prefix                                   'theme-face-strong)
    (set-face 'helm-ff-dotted-directory                          'theme-face-faded)
    (set-face 'helm-ff-directory                                'theme-face-strong)
    (set-face 'helm-ff-executable                               'theme-face-popout)))

(defun theme-apply--helm-grep ()
  "Derive helm faces from nano faces."
  (with-eval-after-load 'helm-grep
    (set-face 'helm-grep-match                                  'theme-face-strong)
    (set-face 'helm-grep-file                                    'theme-face-faded)
    (set-face 'helm-grep-lineno                                  'theme-face-faded)
    (set-face 'helm-grep-finish                                'theme-face-default)))

(defun theme-apply--company ()
  "Derive company tooltip window from nano faces."
  (with-eval-after-load 'company
    (set-face 'company-tooltip-selection                   '(theme-face-strong theme-face-subtle))
    (set-face-attribute 'company-tooltip-selection nil :background theme-color-popout)
    
    (set-face 'company-tooltip                                               'theme-face-subtle)

    (set-face 'company-scrollbar-fg                                          'theme-face-faded)
    (set-face-attribute 'company-scrollbar-fg nil :background theme-color-foreground)
    
    (set-face 'company-scrollbar-bg                                          'theme-face-default)
    (set-face-attribute 'company-scrollbar-bg nil :background theme-color-faded)

    (set-face 'company-tooltip-common                                        'theme-face-faded)
    (set-face 'company-tooltip-common-selection            '(theme-face-strong theme-face-subtle))
    (set-face-attribute 'company-tooltip-common-selection nil :background theme-color-popout)
    
    (set-face 'company-tooltip-annotation                                    'theme-face-default)
    (set-face 'company-tooltip-annotation-selection        '(theme-face-strong theme-face-subtle))))

(defun theme-apply--vertico-posframe ()
  "Derive vertico and vertico-posframe faces from theme colors."
  (with-eval-after-load 'vertico
    (set-face-attribute 'vertico-current nil
                        :inherit nil
                        :extend nil
                        :weight 'normal
                        :background (or (and (boundp 'theme-color-faded) theme-color-faded)
                                        "#A49C93")
                        :foreground "#2b2b2b"))
  (with-eval-after-load 'vertico-posframe
    (let ((border-color (or (and (boundp 'theme-color-faded) theme-color-faded)
                            "#E8E2DA")))
      (set-face-attribute 'vertico-posframe nil
                          :background (or (and (boundp 'theme-color-highlight) theme-color-highlight)
                                          (face-background 'default))
                          :foreground (face-foreground 'default))
      (set-face-attribute 'vertico-posframe-border nil
                          :background border-color
                          :foreground border-color)
      (when (facep 'child-frame-border)
        (set-face-attribute 'child-frame-border nil
                            :background border-color
                            :foreground border-color)))))

(defun theme-apply ()
  "Derive many, many faces from the core nano faces."
  (theme--basics)
  (theme-apply--font-lock)
  (theme-apply--mode-line)
  (theme-apply--minibuffer)
  (theme-apply--buttons)
  (theme-apply--info)
  (theme-apply--bookmark)
  (theme-apply--speedbar)
  (theme-apply--message)
  (theme-apply--outline)
  (theme-apply--customize)
  (theme-apply--package)
  (theme-apply--flyspell)
  (theme-apply--ido)
  (theme-apply--diff)
  (theme-apply--term)
  (theme-apply--calendar)
  (theme-apply--agenda)
  (theme-apply--org)
  (theme-apply--mu4e)
  (theme-apply--elfeed)
  (theme-apply--deft)
  (theme-apply--rst)
  (theme-apply--markdown)
  (theme-apply--ivy)
  (theme-apply--helm)
  (theme-apply--helm-swoop)
  (theme-apply--helm-occur)
  (theme-apply--helm-ff)
  (theme-apply--helm-grep)
  (theme-apply--hl-line)
  (theme-apply--company)
  (theme-apply--vertico-posframe))

(defun theme-refresh ()
  "Convenience function which refreshes the theme-apply.
Calls \(theme-faces\) and \(theme-apply\) sequentially."
  (interactive)
  (progn
    (theme-faces)
    (theme-apply)))


(add-to-list 'custom-theme-load-path (expand-file-name "lisp/themes" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "~/.cache/kuro"))

;; Kuro dynamic theming support
(defvar kuro-theme-cache-file (expand-file-name "~/.cache/kuro/kuro-theme.el"))
(defvar kuro-theme-watch-descriptor nil)

(defun kuro-reload-theme ()
  "Dynamically reload the generated Kuro theme from disk."
  (interactive)
  (let ((cache-dir (expand-file-name "~/.cache/kuro")))
    (add-to-list 'custom-theme-load-path cache-dir)
    (add-to-list 'custom-theme-load-path (expand-file-name "lisp/themes" user-emacs-directory))
    ;; Disable any currently active themes so new face definitions take precedence
    (dolist (th custom-enabled-themes)
      (disable-theme th))
    (if (file-exists-p kuro-theme-cache-file)
        (progn
          (load-file kuro-theme-cache-file)
          (enable-theme 'kuro))
      (load-theme 'kuro t))
    (when (fboundp 'theme-faces)
      (theme-faces))
    (when (fboundp 'theme-apply)
      (theme-apply))
    (message "Kuro theme active.")))

(defun kuro-setup-theme-watch ()
  "Watch ~/.cache/kuro/kuro-theme.el for live updates across desktop theme switches."
  (when (and (require 'filenotify nil t)
             (null kuro-theme-watch-descriptor))
    (let ((target (if (file-exists-p kuro-theme-cache-file)
                      kuro-theme-cache-file
                    (expand-file-name "~/.cache/kuro"))))
      (when (file-exists-p target)
        (setq kuro-theme-watch-descriptor
              (file-notify-add-watch
               target
               '(change)
               (lambda (_event)
                 (run-with-timer 0.05 nil #'kuro-reload-theme))))))))

(defun theme-toggle ()
  "Toggle between Kuro, Boba Dark, and Boba Light themes."
  (interactive)
  (cond ((string= theme-var "kuro")
         (disable-theme 'kuro)
         (load-theme 'boba t)
         (theme-refresh)
         (message "Switched to Boba Light Mode"))
        ((string= theme-var "boba")
         (disable-theme 'boba)
         (load-theme 'boba-dark t)
         (theme-refresh)
         (message "Switched to Boba Dark Mode"))
        (t
         (kuro-reload-theme)
         (message "Switched to Kuro Theme"))))

;; ==========================================
;; Custom Theme Setup for Atomic Emacs
;; ==========================================

;; Override Nano defaults before initializing
(setq theme-font-family-monospaced "JetBrainsMono Nerd Font"
      theme-font-family-proportional "Sans Serif"
      theme-font-size 11)

;; Apply default font attributes early
(set-face-attribute 'default nil
                    :family theme-font-family-monospaced
                    :height (* theme-font-size 10))

;; Initialize theme: prefer the active Kuro desktop theme, fallback to Boba
(if (or (file-exists-p kuro-theme-cache-file)
        (locate-file "kuro-theme.el" custom-theme-load-path))
    (progn
      (kuro-reload-theme)
      (kuro-setup-theme-watch))
  (theme-set-boba)
  (load-theme 'boba t)
  (theme-faces)
  (theme-apply))

;; Ensure new GUI frames created by emacsclient inherit the active Kuro theme
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (when (or (file-exists-p kuro-theme-cache-file)
                        (locate-file "kuro-theme.el" custom-theme-load-path))
                (kuro-reload-theme)))))

;; Sane underline behavior
(setq-default x-underline-at-descent-line t)

(provide 'ui/theme)
