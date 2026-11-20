;;; writer.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'org)
(require 'org-indent)
(require 'org-element)
(require 'ui/base-colors)
(require 'ui/faces)

;; 
;;             prefix  
;;           |<------>|

;; border -> |<------>| * Headline level 1  # Unnumbered
;;           |<------>| 1 Headline level 1  # Numbered
;;
;;           |<----->| ** Headline level 2  # Unnumbered
;;           |<---->| 1.1 Headline level 2  # Numbered
;;
;;           |<---->| *** Headline level 3  # Unumbered
;;           |<-->| 1.1.1 Headline level 3  # Numbered
;; etc.
;;
;; This works if the number of sections at a given level is < 10.


(defun writer-mode--num-format (numbering)
  "Alternative numbering format for org-num.

First level: 1 | xxx
Second level: 1.1 — xxx
Third level: 1.1.1 - xxx
etc.
"""
  (if (= (length numbering) 1)
      (propertize (concat (mapconcat
                           #'number-to-string
                           numbering ".") " | " )
                  'face `(:family "Roboto Condensed"
                          :height 250
                          :foreground ,theme-color-faded))
    (propertize (concat (mapconcat
                         #'number-to-string
                         numbering ".") " — " )
                'face `(:family "Roboto Condensed"
                        :foreground ,theme-color-faded))))

;; Specific face for headline stars
(font-lock-add-keywords 'writer-mode
             '(("^*+ " 0 `(:family "Roboto Mono"
                           :height 140
                           :foreground ,theme-color-faded) prepend)
               ) 'append)

(defun writer-mode--compute-prefixes (orig-fun &rest args)
  "Compute prefix strings for regular text and headlines."
  (if (not (derived-mode-p 'writer-mode))
      (apply orig-fun args)
    (setq org-indent--heading-line-prefixes
          (make-vector org-indent--deepest-level nil))
    (setq org-indent--inlinetask-line-prefixes
          (make-vector org-indent--deepest-level nil))
    (setq org-indent--text-line-prefixes
          (make-vector org-indent--deepest-level nil))

    (let* ((min-indent 5)
           (levels (org-element-map
                       (org-element-parse-buffer) 'headline
                     #'(lambda (item)
                         (org-element-property :level item))))
           (indent (+ 1 (if levels (seq-max levels) 1)))
           (indent (max indent min-indent)))
      
      (dotimes (n org-indent--deepest-level)
        (aset org-indent--heading-line-prefixes n
              (make-string
               (min indent (max 0 (- indent 1 n))) ?\s))
        (aset org-indent--inlinetask-line-prefixes n
              (make-string indent ?\s))
        (aset org-indent--text-line-prefixes n
              (make-string indent ?\s))))))


;;;###autoload
(define-derived-mode writer-mode org-mode "NΛNO writer"

  ;; Faces
  (face-remap-add-relative 'org-level-1
                           :overline theme-color-subtle
                           :family "Roboto" :height 180)
  (face-remap-add-relative 'org-level-2
                           :family "Roboto" :height 160)
  (face-remap-add-relative 'org-level-3
                           :family "Roboto" :height 150)
  (face-remap-add-relative 'org-document-info
                           :inherit 'theme-face-faded)
  (face-remap-add-relative 'org-document-title
                           :foreground theme-color-foreground
                           :family "Roboto Slab"
                           :height 200
                           :weight 'medium)
  ;; hide title / author ... keywords
  (setq-local org-hidden-keywords '(title author date startup))

  ;; Header line
  (setq header-line-format nil)

  ;; Layout
  (setq fill-column 72)
  (setq-default line-spacing 1)

  ;; Indentation
  (setq org-startup-folded nil)
  (org-indent-mode)
  (setq org-level-color-stars-only nil)
  (setq org-hide-leading-stars nil)
  (advice-add 'org-indent--compute-prefixes :around
              #'writer-mode--compute-prefixes)

  ;; Numbering
  (when (require 'org-num nil t)
    (setq org-num-skip-unnumbered t)
    (setq org-num-skip-footnotes t)
    (setq org-num-max-level 2)
    (setq org-num-face nil)
    (org-num-mode)
    (setq org-num-format-function 'writer-mode--num-format)))

;;;###autoload
(defun my-toggle-writer-mode ()
  "Toggle between writer-mode and regular org-mode."
  (interactive)
  (if (eq major-mode 'writer-mode)
      (progn
        (org-mode)
        (message "Switched to standard Org Mode"))
    (progn
      (writer-mode)
      (message "Switched to NΛNO Writer Mode"))))

(provide 'ui/writer)
