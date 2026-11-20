;;; margin.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'bookmark)

(defgroup org-margin nil
  "org margin"
  :group 'convenience)

(defcustom margin-headers
  (list (cons 'stars (list (propertize "     *" 'face 'org-level-1)
                           (propertize "    **" 'face 'org-level-2)
                           (propertize "   ***" 'face 'org-level-3)
                           (propertize "  ****" 'face 'org-level-4)
                           (propertize " *****" 'face 'org-level-5)
                           (propertize "******" 'face 'org-level-6)))
        (cons 'H-txt (list (propertize "H1" 'face '(font-lock-comment-face default))
                           (propertize "H2" 'face '(font-lock-comment-face default))
                           (propertize "H3" 'face '(font-lock-comment-face default))
                           (propertize "H4" 'face '(font-lock-comment-face default))
                           (propertize "H5" 'face '(font-lock-comment-face default))
                           (propertize "H6" 'face '(font-lock-comment-face default))))
        ;; Uncomment if you want to use svg tags for markers (you'll to load svg-lib)
        ;; (cons 'H-svg (list (svg-lib-tag "H1" 'org-level-1)
        ;;                     (svg-lib-tag "H2" 'org-level-2)
        ;;                     (svg-lib-tag "H3" 'org-level-3)
        ;;                     (svg-lib-tag "H4" 'org-level-4)
        ;;                     (svg-lib-tag "H5" 'org-level-5)
        ;;                     (svg-lib-tag "H6" 'org-level-6)))
        )
  "List of marker sets for header"

  :type '(repeat (cons symbol (repeat (choice (string :tag "String")
                                              (sexp :tag "Image")))))
  :group 'org-margin)

(defcustom margin-markers
  (list (cons "\\(#\\+begin_src\\)"
              (propertize " " 'face '(font-lock-comment-face bold)))
        (cons "\\(#\\+begin_quote\\)"
              (propertize " " 'face '(font-lock-comment-face bold))))
    "A list of (regex . marker) that put a marker in the margin for
 each match"

    :type '(repeat (cons regexp (choice (string :tag "String")
                                        (sexp :tag "Image"))))
    :group 'org-margin)

(defcustom margin-headers-set 'H-txt
  "Headers set to use in the margin. margin-mode needs to be
activated for changes to take effect."
  :type '(choice (const :tag "Org (stars)" stars)
                 ;; (const :tag "HTML (svg)" H-svg)
                 (const :tag "HTML (text)" H-txt))
  :group 'org-margin)

(defcustom margin-bookmark (propertize "  " 'face '(error bold))
  "Bookmark symbol"
  :type '(choice (string :tag "String")
                 (sexp :tag "Image"))
  :group 'org-margin)
  
  
(defcustom margin-max-level 6
  "Maximum header level to consider"
  :type 'integer
  :group 'org-margin)
  

(defun margin--set-margin-mark (_orig-fun)
   "Apply a colorized overlay to the bookmarked location.
 See user option `bookmark-fringe-mark'."
   (let ((bm (make-overlay (pos-bol) (1+ (pos-bol)))))
     (overlay-put bm 'category 'bookmark)
     (overlay-put bm 'evaporate t)
     (overlay-put bm 'before-string
                  (propertize " " 'face 'theme-color-critical 'display
                              `((margin left-margin) ,margin-bookmark)))))

(defun margin-mode-off ()
  "Deactivate margin mode"

  (interactive)
  
  ;; Restore margin
  (set-window-margins (selected-window) margin--left-margin-width)
  (setq left-margin-width margin--left-margin-width
        font-lock-extra-managed-props margin--font-lock-extra-managed-props
        font-lock-keywords margin--font-lock-keywords)
  
  ;; Remove margin bookmark
  (advice-remove #'bookmark--set-fringe-mark
                 #'margin--set-margin-mark)

  (font-lock-update))

(defvar-local margin--font-lock-extra-managed-props nil
  "font-lock-extra-managed-props before enterign org margin mode")
  
(defvar-local margin--left-margin-width nil
  "left-wargin-width before enterign org margin mode")

(defvar-local margin--font-lock-keywords font-lock-keywords
  "font-lock-keywords before enterign org margin mode")

(defun margin-mode-on ()
  "Activate margin mode"
  
  (interactive)

  ;; Only in org-mode
  (unless (derived-mode-p 'org-mode)
    (error "margin-mode can only be activated in org-mode"))

  ;; Not compatible with org-indent-mode 
  (when (and (boundp 'org-indent-mode) org-indent-mode)
    (error "org margin mode is not compatible with org-indent-mode"))

  ;; Make sure these properties are handled by font-lock
  (setq-local margin--font-lock-extra-managed-props font-lock-extra-managed-props)
  (add-to-list 'font-lock-extra-managed-props 'display)
  (add-to-list 'font-lock-extra-managed-props 'wrap-prefix)
  (add-to-list 'font-lock-extra-managed-props 'line-prefix)

  ;; Reset org mode font lock before adding our own keywords
  ;; (org-mode)
    
  (let* ((header-set (cdr (assoc margin-headers-set margin-headers)))
         (header-widths (mapcar
            (lambda (item)
              (cond ((imagep item) (truncate (car (image-size item))))
                    ((stringp item) (length item))
                    (t 0))) header-set))
         (marker-widths (mapcar
            (lambda (item)
              (let ((item (cdr item)))
                    (cond ((imagep item) (truncate (car (image-size item))))
                          ((stringp item) (length item))
                          (t 0)))) margin-markers))
         (max-width (max (apply #'max header-widths)
                         (apply #'max marker-widths)))
         (max-level (min margin-max-level (length header-set)))
         (keyword (format "^\\(\\*\\{1,%s\\} \\)" max-level)))

    ;; Margin text is aligned to the left. We thus add 1 to the
    ;; max-width in order to have a single space between prefix and
    ;; header.
    (setq-local margin--left-margin-width left-margin-width)
    (set-window-margins (selected-window) (1+ max-width))
    (setq-local left-margin-width (1+ max-width))

    (setq-local margin--font-lock-keywords font-lock-keywords)
    
    ;; Add header markers
    (when (> max-level 0)
      (font-lock-add-keywords nil
         `((,keyword
            1 `(face nil
                     display ((margin left-margin)
                              ,(nth (- (length (match-string 1)) 2)
                                    ',header-set))) append)))))
  ;; Add custom markers
  (dolist (item margin-markers)
    (let ((regex (car item))
          (marker (cdr item)))
      (font-lock-add-keywords nil
         `((,regex
            1 `(face nil
                line-prefix ,(propertize " " 'display
                                         '((margin left-margin) ,marker)))
        prepend)) 'append)))

  ;; Add margin bookmark
  (advice-add #'bookmark--set-fringe-mark
              :around #'margin--set-margin-mark)
  (font-lock-update))

;;;###autoload
(define-minor-mode margin-mode
  "org-margin mode allows to outdent headers by moving leading
 stars into the margin and transform them into markers depending
 on the chosen style."

  :global nil
  
  (if margin-mode
      (margin-mode-on)
    (margin-mode-off)))

(provide 'syntax/margin)
;;; org-margin.el ends here
