;;; compact.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(setq default-frame-alist
      (append (list
           '(font . "Roboto Mono:style=Light:size=14")
	       '(min-height . 1) '(height    . 45)
	       '(min-width  . 1) '(width      . 81)
           '(vertical-scroll-bars . nil)
           '(internal-border-width . 1)
           '(left-fringe    . 24)
           '(right-fringe   . 24)
           '(tool-bar-lines . 0)
           '(menu-bar-lines . 0))))


(set-face-attribute 'header-line nil
                    :foreground boba-light-foreground
                    :background boba-light-subtle
                    :underline nil
                    :box `(:line-width 4
                           :color ,boba-light-background
                           :style nil))

(set-face-attribute 'internal-border nil :background boba-light-foreground)
(set-face-foreground 'vertical-border boba-light-subtle)
(window-divider-mode 0)

(defun modeline-compose (status name primary secondary)
  "Compose a string with provided information"
  (let* ((prefix (cond ((string= status "**")
                        (propertize "[M] "
                                    'face `(:inherit bold
                                            :foreground ,boba-light-foreground)))
                       ((string= status "RO")
                        (propertize "[R] "
                                    'face `(:inherit bold
                                            :foreground ,boba-light-foreground)))
                       (t
                        (propertize ""
                                    'face `(
                                            :foreground ,boba-light-foreground)))))
         (name (propertize name 'face `(:inherit bold)))
         (left (concat
                (propertize " " 'face nil 'display '(raise -0.30))
                prefix
                name
                (propertize " " 'face nil 'display '(raise +0.25))
                ;; " "
                primary))
         (right (concat (propertize secondary
                                    'face `(:foreground ,boba-light-faded))
                        (propertize " " 'face nil)))
         (available-width (- (window-total-width nil 'floor)
                             (if (display-graphic-p) 1 0)
                             (length left) (length right)))
	 (available-width (max 1 available-width)))
    (concat left (make-string available-width ?\ ) right)))

(provide 'ui/compact)

