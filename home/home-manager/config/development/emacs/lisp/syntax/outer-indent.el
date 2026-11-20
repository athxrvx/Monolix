;;; outer-indent.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'org)
(require 'org-num)
(require 'org-indent)


;;; Internal variables

(defvar-local outer-indent--overlays nil
  "List of overlays used for showing/hiding stars.")


;;; Internal functions

(defun outer-indent--prefix-length (level)
  "Compute headline prefix length at a given LEVEL."
  (if org-num-mode
      (if (or (not org-num-max-level) (<= level org-num-max-level))
          (length (funcall org-num-format-function (make-list level 1)))
        (+ 1 level))
    (+ 1 level)))

(defun outer-indent--compute-prefixes (orig-fun &rest args)
  "Compute prefix strings for regular text and headlines."
  (if (not (and (derived-mode-p 'org-mode)
                (bound-and-true-p outer-indent-mode)))
      (apply orig-fun args)
    (setq org-indent--heading-line-prefixes
          (make-vector org-indent--deepest-level nil))
    (setq org-indent--inlinetask-line-prefixes
          (make-vector org-indent--deepest-level nil))
    (setq org-indent--text-line-prefixes
          (make-vector org-indent--deepest-level nil))

    (let* ((headline-levels (or (org-element-map
                                    (org-element-parse-buffer) 'headline
                                  #'(lambda (item)
                                      (org-element-property :level item)))
                                '()))
           (max-level (if headline-levels (seq-max headline-levels) 1))
           ;; We could also iterate over each evel to get maximum length
           ;; Instead, we take the length of the deepest numbered level.
           (line-indentation (outer-indent--prefix-length
                              (if (and org-num-mode org-num-max-level)
                                  (min org-num-max-level max-level)
                                max-level)))
           (headline-indentation))
      (dotimes (level org-indent--deepest-level)
        (setq headline-indentation
              (max 0 (- line-indentation
                        (outer-indent--prefix-length level))))
        (aset org-indent--inlinetask-line-prefixes level
              (make-string line-indentation ?\s))
        (aset org-indent--text-line-prefixes level
              (make-string line-indentation ?\s))
        (aset org-indent--heading-line-prefixes level
              (make-string headline-indentation ?\s))))))


(defun outer-indent--clear ()
  "Remove all stars hiding overlays in current buffer."
  (mapc #'delete-overlay outer-indent--overlays)
  (setq outer-indent--overlays nil))
  

(defun outer-indent--hideshow-stars ()
  "Remove all stars hiding overlays in current buffer."

  (outer-indent--clear)
  (when org-num-mode
     (let ((num-stars (if org-num-max-level
                          (format "\\(^*\\{1,%d\\} \\)" org-num-max-level)
                        "\\(^*+ \\)")))
       (save-excursion
         (goto-char (point-min))
         (while (re-search-forward num-stars nil t)
           (let ((overlay (make-overlay (match-beginning 1) (match-end 1))))
             (overlay-put overlay 'display "")
             (push overlay outer-indent--overlays))))))

  ;; Force recomputation of indentations
  (if org-indent-mode
       (org-indent-mode t)))


;;; Public functions

(define-minor-mode outer-indent-mode
  "Outer indent mode for org buffer."
  :init-value nil
  
  (cond
   ;; Minor mode ON
   (outer-indent-mode
    (unless (derived-mode-p 'org-mode)
      (user-error "Cannot activate headline numbering outside Org mode"))
    (advice-add 'org-indent--compute-prefixes :around
                #'outer-indent--compute-prefixes)
    (add-hook 'org-num-mode-hook
              #'outer-indent--hideshow-stars)
    (org-indent-mode t))
   
   ;; Minor mode OFF
   (t
    (outer-indent--clear)
    (advice-remove 'org-indent--compute-prefixes
                   #'outer-indent--compute-prefixes)
    (remove-hook 'org-num-mode-hook
                 #'outer-indent--hideshow-stars)
    (org-indent-mode t))))
  
(provide 'syntax/outer-indent)

;;; org-outer-indent.el ends here
