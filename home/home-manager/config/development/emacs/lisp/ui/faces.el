;;; faces.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'ui/base-colors)



(defcustom theme-font-family-monospaced "Roboto Mono"
  "Name of the font-family to use for nano.
Defaults to Roboto Mono. Customizing this might lead to conflicts
if the family does not have sufficient bold/light etc faces."
  :group 'theme
  :type 'string)

(defcustom theme-font-family-proportional nil
  "Font to use for variable pitch faces.
Setting this allows nano to display variable pitch faces when,
for instance, 'variable-pitch-mode' or 'mixed-pitch-mode' is active in a buffer.
Defaults to nil."
  :group 'theme
  :type 'string)

(defcustom theme-font-size 14
  "Default value for the font size of theme-apply in pt units.
Note: to change this after startup, call
\(theme-faces\) and \(theme-applys\)."
  :group 'theme
  :type 'integer)

;; A theme is fully defined by these seven faces

(defface theme-face-default nil
  "Default face is used for regular information."
  :group 'theme)

(defface theme-face-variable-pitch nil
  "Default variable-pitch face is used for variable pitch mode."
  :group 'theme)

(defface theme-face-critical nil
  "Critical face is for information that requires immediate action.
It should be of high constrast when compared to other faces. This
can be realized (for example) by setting an intense background
color, typically a shade of red. It must be used scarcely."
  :group 'theme)

(defface theme-face-popout nil
  "Popout face is used for information that needs attention.
To achieve such effect, the hue of the face has to be
sufficiently different from other faces such that it attracts
attention through the popout effect."
  :group 'theme)

(defface theme-face-strong nil
  "Strong face is used for information of a structural nature.
It has to be the same color as the default color and only the
weight differs by one level (e.g., light/regular or
regular/bold). IT is generally used for titles, keywords,
directory, etc."
  :group 'theme)

(defface theme-face-salient nil
  "Salient face is used for information that are important.
To suggest the information is of the same nature but important,
the face uses a different hue with approximately the same
intensity as the default face. This is typically used for links."
  :group 'theme)

(defface theme-face-faded nil
  "Faded face is for information that are less important.
It is made by using the same hue as the default but with a lesser
intensity than the default. It can be used for comments,
secondary information and also replace italic (which is generally
abused anyway)."
  :group 'theme)

(defface theme-face-subtle nil
  "Subtle face is used to suggest a physical area on the screen.
It is important to not disturb too strongly the reading of
information and this can be made by setting a very light
background color that is barely perceptible."
  :group 'theme)

(defface theme-face-header-default nil
  "Default face for ther header line."
  :group 'theme)

(defface theme-face-header-critical nil
  "Critical face for ther header line."
  :group 'theme)

(defface theme-face-header-popout nil
  "Popout face for ther header line."
  :group 'theme)

(defface theme-face-header-strong nil
  "Strong face for ther header line."
  :group 'theme)

(defface theme-face-header-salient nil
  "Salient face for ther header line."
  :group 'theme)

(defface theme-face-header-faded nil
  "Faded face for ther header line."
  :group 'theme)

(defface theme-face-header-subtle nil
  "Subtle face for ther header line."
  :group 'theme)

(defface theme-face-header-highlight nil
  "Highlight face for ther header line."
  :group 'theme)

(defface theme-face-header-separator nil
  "Face for separating item in the header line (internal use)"
  :group 'theme)

(defface theme-face-header-filler nil
  "Face compsenting spaces in the header line (internal use) "
  :group 'theme)

(defface theme-face-tag-default nil
  "Default face for tags"
  :group 'theme)

(defface theme-face-tag-faded nil
  "Faded face for tags"
  :group 'theme)

(defface theme-face-tag-strong nil
  "Strong face for tags"
  :group 'theme)

(defface theme-face-tag-salient nil
  "Salient face for tags"
  :group 'theme)

(defface theme-face-tag-popout nil
  "Popout face for tags"
  :group 'theme)

(defface theme-face-tag-critical nil
  "Critical face for tags"
  :group 'theme)

(defun theme-what-faces (pos)
  "Get the font faces at POS."
  (interactive "d")
  (let ((faces (remq nil
                     (list
                      (get-char-property pos 'read-face-name)
                      (get-char-property pos 'face)
                      (plist-get (text-properties-at pos) 'face)))))
    (message "Faces: %s" faces)))

(defun theme-faces ()
  "Derive face attributes for theme-faces using theme-apply values."
  (set-face-attribute 'theme-face-default nil
                      :foreground theme-color-foreground
                      :background theme-color-background
                      :family     theme-font-family-monospaced
                      :height       (* theme-font-size 10))
  (set-face-attribute 'theme-face-critical nil
                      :foreground theme-color-foreground
                      :background theme-color-critical)
  (set-face-attribute 'theme-face-popout nil
                      :foreground theme-color-popout)

  (set-face-attribute 'theme-face-variable-pitch nil
                          :foreground (face-foreground 'theme-face-default)
                          :background (face-background 'theme-face-default)
                          :family theme-font-family-proportional
                          :height (* theme-font-size 10))
  (if (display-graphic-p)
      (set-face-attribute 'theme-face-strong nil
                          :foreground theme-color-strong
                          :weight 'medium)
    (set-face-attribute 'theme-face-strong nil
                        :foreground theme-color-strong
                        :weight 'bold))

  (set-face-attribute 'theme-face-salient nil
                      :foreground theme-color-salient
                      :weight 'light)

  (set-face-attribute 'theme-face-faded nil
                      :foreground theme-color-faded
                      :weight 'light)

  (set-face-attribute 'theme-face-subtle nil
                      :background theme-color-subtle)

  (set-face-attribute 'theme-face-header-default nil
                      :foreground theme-color-foreground
                      :background theme-color-subtle
                      :box `(:line-width 1
                                         :color ,theme-color-background
                                         :style nil))

  (set-face-attribute 'theme-face-tag-default nil
                      :foreground theme-color-foreground
                      :background theme-color-background
                      :weight 'regular
                      :height (if (display-graphic-p)
                                  (round
                                   (* 0.85 (* 10 theme-font-size)))
                                                1)
                      :box `(:line-width 1
                                         :color ,theme-color-foreground
                                         :style nil))

  (set-face-attribute 'theme-face-header-strong nil
                      :foreground theme-color-strong
                      :background theme-color-subtle
                      :inherit 'theme-face-strong
                      :box `(:line-width 1
                                         :color ,theme-color-background
                                         :style nil))

  (set-face-attribute 'theme-face-tag-strong nil
                      :foreground theme-color-strong
                      :background theme-color-subtle
                      :weight 'regular
                      :height (if (display-graphic-p)
                                  (round
                                   (* 0.85 (* 10 theme-font-size)))
                                                1)
                      :box `(:line-width 1
                                         :color ,theme-color-strong
                                         :style nil))

  (set-face-attribute 'theme-face-header-salient nil
                      :foreground theme-color-background
                      :background theme-color-salient
                      :box `(:line-width 1
                                         :color ,theme-color-background
                                         :style nil))

  (set-face-attribute 'theme-face-tag-salient nil
                      :foreground theme-color-background
                      :background theme-color-salient
                      :weight 'regular
                      :height (if (display-graphic-p)
                                  (round
                                   (* 0.85 (* 10 theme-font-size)))
                                                1)
                      :box `(:line-width 1
                                         :color ,theme-color-salient
                                         :style nil))

  (set-face-attribute 'theme-face-header-popout nil
                      :foreground theme-color-background
                      :background theme-color-popout
                      :box `(:line-width 1
                                         :color ,theme-color-background
                                         :style nil))

  (set-face-attribute 'theme-face-tag-popout nil
                      :foreground theme-color-background
                      :background theme-color-popout
                      :weight 'regular
                      :height (if (display-graphic-p)
                                  (round
                                   (* 0.85 (* 10 theme-font-size)))
                                                1)
                      :box `(:line-width 1
                                         :color ,theme-color-popout
                                         :style nil))

  (set-face-attribute 'theme-face-header-faded nil
                      :foreground theme-color-background
                      :background theme-color-faded
                      :box `(:line-width 1
                                         :color ,theme-color-background
                                         :style nil))

  (set-face-attribute 'theme-face-tag-faded nil
                      :foreground theme-color-background
                      :background theme-color-faded
                      :weight 'regular
                      :height (if (display-graphic-p)
                                  (round
                                   (* 0.85 (* 10 theme-font-size)))
                                                1)
                      :box `(:line-width 1
                                         :color ,theme-color-faded
                                         :style nil))

  (set-face-attribute 'theme-face-header-subtle nil)

  (set-face-attribute 'theme-face-header-critical nil
                      :foreground theme-color-background
                      :background theme-color-critical
                      :box `(:line-width 1
                                         :color ,theme-color-background
                                         :style nil))
  (set-face-attribute 'theme-face-tag-critical nil
                      :foreground theme-color-background
                      :background theme-color-critical
                      :weight 'regular
                      :height (if (display-graphic-p)
                                  (round
                                   (* 0.85 (* 10 theme-font-size)))
                                                1)
                      :box `(:line-width 1
                                         :color ,theme-color-critical
                                         :style nil))

  (set-face-attribute 'theme-face-header-separator nil
                      :inherit 'theme-face-default
                      :height 0.1)
  (set-face-attribute 'theme-face-header-filler nil
                      :inherit 'theme-face-header-default
                      :height 0.1)
  (set-face-attribute 'theme-face-header-highlight nil
                      :inherit 'theme-face-header-faded
                      :box nil))

;; ==========================================
;; NΛNO Face Aliases for Upstream Compatibility
;; ==========================================
(defface boba-default '((t :inherit theme-face-default)) "Alias for theme-face-default." :group 'nano)
(defface boba-strong '((t :inherit theme-face-strong)) "Alias for theme-face-strong." :group 'nano)
(defface boba-salient '((t :inherit theme-face-salient)) "Alias for theme-face-salient." :group 'nano)
(defface boba-faded '((t :inherit theme-face-faded)) "Alias for theme-face-faded." :group 'nano)
(defface boba-subtle '((t :inherit theme-face-subtle)) "Alias for theme-face-subtle." :group 'nano)
(defface boba-popout '((t :inherit theme-face-popout)) "Alias for theme-face-popout." :group 'nano)
(defface boba-critical '((t :inherit theme-face-critical)) "Alias for theme-face-critical." :group 'nano)
(defface boba-default-i '((t :inherit theme-face-default :inverse-video t)) "Inverse default face." :group 'nano)
(defface boba-faded-i '((t :inherit theme-face-faded :inverse-video t)) "Inverse faded face." :group 'nano)
(defface boba-critical-i '((t :inherit theme-face-critical :inverse-video t)) "Inverse critical face." :group 'nano)
(defface boba-popout-i '((t :inherit theme-face-popout :inverse-video t)) "Inverse popout face." :group 'nano)
(defface boba-salient-i '((t :inherit theme-face-salient :inverse-video t)) "Inverse salient face." :group 'nano)
(defface boba-strong-i '((t :inherit theme-face-strong :inverse-video t)) "Inverse strong face." :group 'nano)

(provide 'ui/faces)
;;; theme-faces.el ends here
