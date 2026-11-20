;;; dashboard.el --- Graphical Bobamacs dashboard -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'cl-lib)
(require 'ui/layout)
(require 'ui/defaults)
(require 'svg-lib nil t)
(require 'svg-icon nil t)

(declare-function mac-start-animation "mac-win" (&rest args) t)

(declare-function consult-recent-file "consult" () t)
(declare-function org-roam-capture "org-roam-capture" (&rest args) t)
(declare-function org-roam-node-find "org-roam-node" (&rest args) t)
(declare-function org-roam-dailies-goto-today "org-roam-dailies" (&rest args) t)
(declare-function org-roam-ui-mode "org-roam-ui" (&rest args) t)
(declare-function boba-sidebar-toggle-org "ui/sidebar" () t)

(defconst dashboard-ascii-logo
  '(" █████  ████████  ██████  ███    ███ ██  ██████ "
    "██   ██    ██    ██    ██ ████  ████ ██ ██      "
    "███████    ██    ██    ██ ██ ████ ██ ██ ██      "
    "██   ██    ██    ██    ██ ██  ██  ██ ██ ██      "
    "██   ██    ██     ██████  ██      ██ ██  ██████ "
    "          B  O  B  A  M  A  C  S"))

(defface dashboard-button-face
  '((t :inherit theme-face-default :weight bold :underline nil))
  "Face used for dashboard buttons.")

(defface dashboard-border-face
  '((t :inherit theme-face-faded))
  "Face used for dashboard card borders.")

(defface dashboard-title-face
  '((t :inherit theme-face-strong :weight bold :height 1.4))
  "Face used for the BOBAMACS title.")

(defface dashboard-stats-face
  '((t :inherit theme-face-faded :height 0.9))
  "Face used for package stats and timing.")

(defface dashboard-card-header-face
  '((t :inherit theme-face-subtle :extend t :weight bold))
  "Face used for card header background.")



(defface dashboard-separator-face
  '((t :inherit dashboard-border-face))
  "Face used for section separators.")

(defface dashboard-modeline-button-hover-face
  '((t :inherit modeline-active :weight bold
       :box (:line-width 6 :color "#cdc5b5")))
  "Face for modeline buttons on hover (slightly darker than modeline bg).")

(define-button-type 'dashboard-button
  'face 'dashboard-button-face
  'mouse-face 'highlight
  'follow-link t)

(defvar-local dashboard-current-page 'home
  "Current active page on the dashboard ('home, 'files, 'notes).")

(defun dashboard-find-file ()
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'find-file)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-recent-file ()
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'consult-recent-file)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-project-switch ()
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'project-switch-project)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-create-roam-note ()
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'org-roam-capture)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-find-roam-node ()
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'org-roam-node-find)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-roam-daily ()
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'org-roam-dailies-goto-today)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-roam-ui ()
  (interactive)
  (call-interactively #'org-roam-ui-mode))

(defun dashboard-sidebar-toggle ()
  (interactive)
  (call-interactively #'boba-sidebar-toggle-org))

(defvar dashboard-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'dashboard-exit)
    (define-key map (kbd "e") #'neotree-toggle)
    (define-key map (kbd "f") #'dashboard-find-file)
    (define-key map (kbd "r") #'dashboard-recent-file)
    (define-key map (kbd "p") #'dashboard-project-switch)
    (define-key map (kbd "c") #'dashboard-cmd-or-create)
    (define-key map (kbd "s") #'dashboard-cmd-or-search)
    (define-key map (kbd "d") #'dashboard-roam-daily)
    (define-key map (kbd "g") #'dashboard-roam-ui)
    (define-key map (kbd "b") #'dashboard-sidebar-toggle)
    (define-key map (kbd "1") #'dashboard-switch-to-home)
    (define-key map (kbd "h") #'dashboard-switch-to-home)
    (define-key map (kbd "2") #'dashboard-switch-to-files)
    (define-key map (kbd "l") #'dashboard-switch-to-files)
    (define-key map (kbd "3") #'dashboard-switch-to-notes)
    (define-key map (kbd "n") #'dashboard-switch-to-notes)
    (define-key map (kbd "j") #'next-line)
    (define-key map (kbd "k") #'previous-line)
    (define-key map (kbd "RET") #'push-button)
    (define-key map (kbd "?") (lambda ()
                                (interactive)
                                (require 'which-key)
                                (which-key-show-keymap dashboard-mode-map)))
    map)
  "Keymap for `dashboard-mode'.")

(with-eval-after-load 'evil
  (eval
   '(progn
      (evil-define-key 'normal dashboard-mode-map
        (kbd "q") #'dashboard-exit
        (kbd "e") #'neotree-toggle
        (kbd "f") #'dashboard-find-file
        (kbd "r") #'dashboard-recent-file
        (kbd "p") #'dashboard-project-switch
        (kbd "c") #'dashboard-cmd-or-create
        (kbd "s") #'dashboard-cmd-or-search
        (kbd "d") #'dashboard-roam-daily
        (kbd "g") #'dashboard-roam-ui
        (kbd "b") #'dashboard-sidebar-toggle
        (kbd "1") #'dashboard-switch-to-home
        (kbd "h") #'dashboard-switch-to-home
        (kbd "2") #'dashboard-switch-to-files
        (kbd "l") #'dashboard-switch-to-files
        (kbd "3") #'dashboard-switch-to-notes
        (kbd "n") #'dashboard-switch-to-notes
        (kbd "j") #'next-line
        (kbd "k") #'previous-line
        (kbd "RET") #'push-button
        (kbd "?") (lambda ()
                    (interactive)
                    (require 'which-key)
                    (which-key-show-keymap dashboard-mode-map)))
      (evil-define-key 'motion dashboard-mode-map
        (kbd "q") #'dashboard-exit
        (kbd "e") #'neotree-toggle
        (kbd "f") #'dashboard-find-file
        (kbd "r") #'dashboard-recent-file
        (kbd "p") #'dashboard-project-switch
        (kbd "c") #'dashboard-cmd-or-create
        (kbd "s") #'dashboard-cmd-or-search
        (kbd "d") #'dashboard-roam-daily
        (kbd "g") #'dashboard-roam-ui
        (kbd "b") #'dashboard-sidebar-toggle
        (kbd "1") #'dashboard-switch-to-home
        (kbd "h") #'dashboard-switch-to-home
        (kbd "2") #'dashboard-switch-to-files
        (kbd "l") #'dashboard-switch-to-files
        (kbd "3") #'dashboard-switch-to-notes
        (kbd "n") #'dashboard-switch-to-notes
        (kbd "j") #'next-line
        (kbd "k") #'previous-line
        (kbd "RET") #'push-button
        (kbd "?") (lambda ()
                    (interactive)
                    (require 'which-key)
                    (which-key-show-keymap dashboard-mode-map))))))

(defvar boba-toolbar--active nil
  "Non-nil when context toolbar is active.")

(define-minor-mode boba-modeline-buttons-mode
  "Minor mode to show Options/File Tree/Sidebar buttons in all buffers."
  :global t
  :lighter " Boba"
  (if boba-modeline-buttons-mode
      (setq header-line-format
            `(:eval (boba-modeline--buttons-format)))
    (when (eq header-line-format
              `(:eval (boba-modeline--buttons-format)))
      (setq header-line-format nil))))

(defun boba-modeline--buttons-format ()
  "Return header-line format with global buttons."
  (let* ((btn-face '(:inherit modeline-active :weight bold))
         (options-btn (propertize
                       " Options "
                       'face btn-face
                       'keymap (let ((m (make-sparse-keymap)))
                                 (define-key m [header-line mouse-1]
                                   (lambda (_e) (interactive "e") (boba-toolbar-toggle)))
                                 (define-key m [header-line mouse-2]
                                   (lambda (_e) (interactive "e") (boba-toolbar-toggle)))
                                 m)
                       'mouse-face 'dashboard-modeline-button-hover-face
                       'help-echo "Toggle context toolbar"))
         (files-btn (propertize
                     " File Tree "
                     'face btn-face
                     'keymap (let ((m (make-sparse-keymap)))
                               (define-key m [header-line mouse-1]
                                 (lambda (_e) (interactive "e") (neotree-toggle)))
                               (define-key m [header-line mouse-2]
                                 (lambda (_e) (interactive "e") (neotree-toggle)))
                               m)
                     'mouse-face 'dashboard-modeline-button-hover-face
                     'help-echo "Toggle file tree"))
         (sidebar-btn (propertize
                       " Sidebar "
                       'face btn-face
                       'keymap (let ((m (make-sparse-keymap)))
                                 (define-key m [header-line mouse-1]
                                   (lambda (_e) (interactive "e") (dashboard-sidebar-toggle)))
                                 (define-key m [header-line mouse-2]
                                   (lambda (_e) (interactive "e") (dashboard-sidebar-toggle)))
                                 m)
                       'mouse-face 'dashboard-modeline-button-hover-face
                       'help-echo "Toggle sidebar"))
         (separator "  "))
    (concat "  " options-btn separator files-btn separator sidebar-btn)))

;; Buttons mode is intentionally disabled — header buttons removed per design
;; (boba-modeline-buttons-mode 1)

(defvar boba-toolbar--active nil
  "Non-nil when context toolbar is active.")

(defun boba-toolbar--get-context-buttons ()
  "Return context-aware toolbar buttons based on major mode."
  (cond
   ((derived-mode-p 'org-mode)
    '(( "Bold"      . (lambda () (interactive) (org-toggle-bold)))
      ( "Italic"    . (lambda () (interactive) (org-toggle-italic)))
      ( "Underline" . (lambda () (interactive) (org-toggle-underline)))
      ( "Strike"    . (lambda () (interactive) (org-toggle-strikethrough)))
      ( "Code"      . (lambda () (interactive) (org-toggle-verbatim)))
      ( "Link"      . (lambda () (interactive) (org-insert-link)))
      ( "Heading"   . (lambda () (interactive) (org-insert-heading)))
      ( "List"      . (lambda () (interactive) (org-insert-item)))
      ( "Source"    . (lambda () (interactive) (org-insert-structure-template 's)))
      ( "Quote"     . (lambda () (interactive) (org-insert-structure-template 'q)))
      ( "Export"    . (lambda () (interactive) (org-export-dispatch)))
      ( "Roam"      . (lambda () (interactive) (org-roam-node-find)))
      ( "Capture"   . (lambda () (interactive) (org-capture)))))
   ((or (derived-mode-p 'prog-mode) (derived-mode-p 'cc-mode))
    '(( "Run"        . (lambda () (interactive) (compile)))
      ( "Test"       . (lambda () (interactive) (compile "make test")))
      ( "Build"      . (lambda () (interactive) (compile "make")))
      ( "Terminal"   . (lambda () (interactive) (term "/bin/bash")))
      ( "LSP"        . (lambda () (interactive) (lsp-execute-code-action)))
      ( "Refactor"   . (lambda () (interactive) (lsp-execute-code-action)))
      ( "Format"     . (lambda () (interactive) (lsp-format-buffer)))
      ( "Debug"      . (lambda () (interactive) (dap-debug)))
      ( "Git"        . (lambda () (interactive) (magit-status)))
      ( "Diff"       . (lambda () (interactive) (vc-diff)))))
   ((derived-mode-p 'text-mode)
    '(( "Word Count" . (lambda () (interactive) (count-words-region (point-min) (point-max))))
      ( "Fill"       . (lambda () (interactive) (fill-paragraph)))
      ( "Spell"      . (lambda () (interactive) (ispell-buffer)))
      ( "Center"     . (lambda () (interactive) (center-line))))
      )
   (t
    '(( "Save"       . (lambda () (interactive) (save-buffer)))
      ( "Save All"   . (lambda () (interactive) (save-some-buffers)))
      ( "Shell"      . (lambda () (interactive) (shell)))
      ( "Dired"      . (lambda () (interactive) (dired))))
      )))

(defun boba-toolbar-toggle ()
  "Toggle context-aware toolbar in header line."
  (interactive)
  (if boba-toolbar--active
      (boba-toolbar--hide)
    (boba-toolbar--show)))

(defun boba-toolbar--show ()
  "Show context-aware toolbar in header line."
  (require 'ui/toolbar)
  (setq boba-toolbar--active t)
  (let ((buttons (boba-toolbar--get-context-buttons)))
    (boba-toolbar "Options:" buttons)))

(defun boba-toolbar--hide ()
  "Hide context-aware toolbar."
  (setq boba-toolbar--active nil)
  (force-mode-line-update))

(defun modeline-dashboard-buttons ()
  "Modeline element: right-aligned dashboard action buttons.
Referenced by `modeline-dashboard-mode' in modeline.el."
  (let* ((btn-face '(:inherit modeline-active :weight bold))
         (options-btn (propertize
                       " Options "
                       'face btn-face
                       'keymap (let ((m (make-sparse-keymap)))
                                 (define-key m [header-line mouse-1]
                                   (lambda (_e) (interactive "e") (boba-toolbar-toggle)))
                                 (define-key m [header-line mouse-2]
                                   (lambda (_e) (interactive "e") (boba-toolbar-toggle)))
                                 m)
                       'mouse-face 'dashboard-modeline-button-hover-face
                       'help-echo "Toggle context toolbar"))
         (files-btn (propertize
                     " File Tree "
                     'face btn-face
                     'keymap (let ((m (make-sparse-keymap)))
                               (define-key m [header-line mouse-1]
                                 (lambda (_e) (interactive "e") (neotree-toggle)))
                               (define-key m [header-line mouse-2]
                                 (lambda (_e) (interactive "e") (neotree-toggle)))
                               m)
                     'mouse-face 'dashboard-modeline-button-hover-face
                     'help-echo "Toggle file tree"))
         (sidebar-btn (propertize
                       " Sidebar "
                       'face btn-face
                       'keymap (let ((m (make-sparse-keymap)))
                                 (define-key m [header-line mouse-1]
                                   (lambda (_e) (interactive "e") (dashboard-sidebar-toggle)))
                                 (define-key m [header-line mouse-2]
                                   (lambda (_e) (interactive "e") (dashboard-sidebar-toggle)))
                                 m)
                       'mouse-face 'dashboard-modeline-button-hover-face
                       'help-echo "Toggle sidebar")))
    (concat "  " options-btn "  " files-btn "  " sidebar-btn)))

(define-derived-mode dashboard-mode special-mode "Dashboard"
  "Major mode for the Bobamacs graphical dashboard."
  (setq mode-name "Dashboard")
  (setq cursor-type nil)
  (setq buffer-read-only t)
  (setq-local line-spacing 1)
  (setq-local header-line-format nil)
  (setq-local vertical-scroll-bar nil)
  (setq-local horizontal-scroll-bar nil))

(defun dashboard-switch-page (page)
  (interactive)
  (when (member page '(home files notes))
    (setq dashboard-current-page page)
    (dashboard-splash)))

(defun dashboard-switch-to-home ()
  (interactive)
  (dashboard-switch-page 'home))

(defun dashboard-switch-to-files ()
  (interactive)
  (dashboard-switch-page 'files))

(defun dashboard-switch-to-notes ()
  (interactive)
  (dashboard-switch-page 'notes))

(defun dashboard-make-icon-string (icon-name &optional fg-color)
  (if (and (fboundp 'svg-icon) (display-graphic-p))
      (let* ((fg (or fg-color (face-foreground 'theme-face-salient nil 'default)))
             (bg (face-background 'default nil 'default))
             (icon (condition-case nil
                       (svg-icon "boxicons" icon-name fg bg 1.0)
                     (error nil))))
        (if icon
            (concat (propertize " " 'display icon) " ")
          ""))
    ""))

(defvar dashboard-drawing-in-progress nil)

(defun dashboard-insert-centered (text &optional face)
  (let* ((clean-text (substring-no-properties text))
         (len (length clean-text))
         (padding (max 0 (/ (- (window-body-width) len) 2))))
    (insert (make-string padding ?\s)
            (if face (propertize text 'face face) text)
            "\n")))

(defun dashboard-pad-to-width (text width)
  (let* ((clean (substring-no-properties text))
         (len (length clean)))
    (if (>= len width)
        text
      (concat text (make-string (- width len) ?\s)))))

(defun dashboard-center-in-width (text width)
  (let* ((clean-text (substring-no-properties text))
         (len (length clean-text))
         (total-pad (- width len))
         (left-pad (/ total-pad 2))
         (right-pad (- total-pad left-pad)))
    (concat (make-string (max 0 left-pad) ?\s)
            text
            (make-string (max 0 right-pad) ?\s))))

(defun dashboard-abbrev-path (path max-len)
  (let ((abbrev (abbreviate-file-name path)))
    (if (<= (length abbrev) max-len)
        abbrev
      (let* ((filename (file-name-nondirectory abbrev))
             (dir (file-name-directory abbrev))
             (dir-components (split-string (directory-file-name dir) "/" t))
             (last-dir (car (last dir-components)))
             (result (if last-dir (concat last-dir "/" filename) filename)))
        (if (<= (length result) (- max-len 4))
            (concat ".../" result)
          (let ((truncated-file (substring filename 0 (min (length filename) (- max-len 4)))))
            (concat "..." truncated-file)))))))

(defun dashboard-make-button-string (label func &optional help)
  (let ((map (make-sparse-keymap))
        (f func))
    (define-key map [mouse-1] (lambda (e) (interactive "e")
                                (call-interactively f)))
    (define-key map [mouse-2] (lambda (e) (interactive "e")
                                (call-interactively f)))
    (define-key map [?\r] (lambda () (interactive)
                            (call-interactively f)))
    (define-key map (kbd "RET") (lambda () (interactive)
                                  (call-interactively f)))
    (define-key map [follow-link] 'mouse-face)
    (propertize label
                'face 'dashboard-button-face
                'mouse-face 'highlight
                'follow-link t
                'keymap map
                'help-echo help)))

(defun dashboard-make-file-button-string (label path &optional help)
  (let ((map (make-sparse-keymap))
        (p path))
    (define-key map [mouse-1] (lambda (e) (interactive "e")
                                (let ((dashboard-buf (get-buffer "*splash*")))
                                  (find-file p)
                                  (when (and dashboard-buf
                                             (buffer-live-p dashboard-buf)
                                             (not (eq (current-buffer) dashboard-buf)))
                                    (kill-buffer dashboard-buf)))))
    (define-key map [mouse-2] (lambda (e) (interactive "e")
                                (let ((dashboard-buf (get-buffer "*splash*")))
                                  (find-file p)
                                  (when (and dashboard-buf
                                             (buffer-live-p dashboard-buf)
                                             (not (eq (current-buffer) dashboard-buf)))
                                    (kill-buffer dashboard-buf)))))
    (define-key map [?\r] (lambda () (interactive)
                            (let ((dashboard-buf (get-buffer "*splash*")))
                              (find-file p)
                              (when (and dashboard-buf
                                         (buffer-live-p dashboard-buf)
                                         (not (eq (current-buffer) dashboard-buf)))
                                (kill-buffer dashboard-buf)))))
    (define-key map (kbd "RET") (lambda () (interactive)
                                  (let ((dashboard-buf (get-buffer "*splash*")))
                                    (find-file p)
                                    (when (and dashboard-buf
                                               (buffer-live-p dashboard-buf)
                                               (not (eq (current-buffer) dashboard-buf)))
                                      (kill-buffer dashboard-buf)))))
    (define-key map [follow-link] 'mouse-face)
    (propertize label
                'face 'dashboard-button-face
                'mouse-face 'highlight
                'follow-link t
                'keymap map
                'help-echo help)))

(defun dashboard--fill-row (content content-width)
  "Return CONTENT padded to CONTENT-WIDTH with spaces.
Preserves text properties (e.g. button faces).
Does NOT include the 1-space padding between │ borders."
  (dashboard-pad-to-width content content-width))

(defun dashboard--card-row (content content-width &optional box-padding)
  "Insert a full card row: │ content │.
The side spaces between │ and content are added automatically."
  (insert (make-string (or box-padding 0) ?\s)
          (propertize "│" 'face 'dashboard-border-face)
          " "
          (dashboard--fill-row content content-width)
          " "
          (propertize "│" 'face 'dashboard-border-face)
          "\n"))

(defun dashboard--card (title content-lines &rest props)
  "Render a card with TITLE header and CONTENT-LINES list of strings.
PROPS may include :card-width (default 80) and :icon."
  (let* ((card-width (min (or (plist-get props :card-width) 80) (window-body-width)))
         (icon-name (or (plist-get props :icon) ""))
         (icon (if (string-prefix-p "bx-" icon-name)
                   (dashboard-make-icon-string icon-name)
                 icon-name))
         (content-width (- card-width 4))
         (box-padding (floor (max 0 (/ (- (window-body-width) card-width) 2)))))
    ;; top border
    (insert (make-string box-padding ?\s)
            (propertize (concat "┌" (make-string (- card-width 2) ?─) "┐") 'face 'dashboard-border-face)
            "\n")
    ;; header row
    (dashboard--card-row (concat "  " icon " " title) content-width box-padding)
    ;; separator
    (insert (make-string box-padding ?\s)
            (propertize (concat "├" (make-string (- card-width 2) ?─) "┤") 'face 'dashboard-separator-face)
            "\n")
    ;; content rows
    (dolist (line content-lines)
      (dashboard--card-row line content-width box-padding))
    ;; bottom border
    (insert (make-string box-padding ?\s)
            (propertize (concat "└" (make-string (- card-width 2) ?─) "┘") 'face 'dashboard-border-face)
            "\n\n")))

(defun dashboard--hero-section ()
  "Insert the BOBAMACS title + stats hero section."
  (insert "\n")
  ;; logo and ascii art intentionally removed — keep it minimal
  ;; BOBAMACS title
  (dashboard-insert-centered "BOBAMACS" 'dashboard-title-face)
  (insert "\n")
  ;; package stats
  (let* ((pkg-count (cond
                     ((fboundp 'straight--build-dir)
                      (length (directory-files (straight--build-dir) nil "^[^.]")))
                     ((bound-and-true-p straight--activated-packages)
                      (hash-table-count straight--activated-packages))
                     ((boundp 'package-activated-list)
                      (length package-activated-list))
                     (t 0)))
         (init-time (emacs-init-time))
         (stats-str (format "%d packages loaded in %s" pkg-count init-time)))
    (dashboard-insert-centered stats-str 'dashboard-stats-face))
  (insert "\n"))

(defun dashboard--make-icon (&optional icon-name)
  "Return an icon string for icon-name using nerd-icons or svg."
  (cond
   ((and icon-name (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
    (nerd-icons-icon-for-file icon-name))
   ((and icon-name (fboundp 'svg-icon) (display-graphic-p))
    (dashboard-make-icon-string icon-name))
   (t "•")))

(defun dashboard--quick-action-row ()
  "Insert a compact row of quick action buttons."
  (let* ((actions
          (list
           (list "f" "Find File" #'dashboard-find-file)
           (list "p" "Projects" #'dashboard-project-switch)
           (list "e" "Explorer" #'neotree-toggle)
            (list "c" "Create" #'dashboard-create-roam-note)
           (list "s" "Search" #'dashboard-find-roam-node)))
         (card-width 80)
         (box-padding (max 0 (/ (- (window-body-width) card-width) 2)))
         (btn-strs
          (mapcar (lambda (act)
                    (let ((key (nth 0 act))
                          (label (nth 1 act))
                          (func (nth 2 act)))
                      (dashboard-make-button-string
                       (format "[%s] %s" key label) func)))
                  actions))
         (group1 (mapconcat #'identity (cl-subseq btn-strs 0 3) "    "))
         (group2 (mapconcat #'identity (cl-subseq btn-strs 3 6) "    ")))
    (dashboard--card "Quick Actions"
                     (list (concat "  " group1)
                           (concat "  " group2))
                     :icon "bx-bolt")))

(defun dashboard--recent-files-section ()
  "Insert recent files card."
  (let* ((files (and (bound-and-true-p recentf-mode) recentf-list))
         (max-files 8)
         (file-items (and files (cl-subseq files 0 (min max-files (length files)))))
         (lines nil))
    (if (not file-items)
        (setq lines (list (propertize "  No recent files" 'face 'theme-face-faded)))
       (dolist (f file-items)
         (let* ((icon-str (if (and (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
                              (concat (nerd-icons-icon-for-file f) " ")
                            (concat (dashboard-make-icon-string "bx-file") " ")))
                (abbrev-path (dashboard-abbrev-path f 60))
                (file-btn (dashboard-make-file-button-string abbrev-path f (format "Open %s" f))))
           (push (concat "  " icon-str file-btn) lines)))
       (setq lines (nreverse lines)))
     (dashboard--card "Recent Files" lines :icon "bx-folder")))

(defun dashboard--recent-projects-section ()
  "Insert recent projects card."
  (when (and (fboundp 'project-known-project-roots) (project-known-project-roots))
    (let* ((projects (project-known-project-roots))
           (max-proj 5)
           (proj-items (cl-subseq projects 0 (min max-proj (length projects))))
           (lines nil))
      (dolist (proj proj-items)
        (let* ((dir (file-name-as-directory proj))
               (name (file-name-nondirectory (directory-file-name dir)))
               (abbrev-dir (abbreviate-file-name dir))
               (max-dir-len (- 60 (length name) 4))
               (abbrev-dir-str (if (> (length abbrev-dir) max-dir-len)
                                   (concat "..." (substring abbrev-dir (- (length abbrev-dir) (- max-dir-len 3))))
                                 abbrev-dir))
               (icon-str (if (and (fboundp 'nerd-icons-octicon) (display-graphic-p))
                             (concat (nerd-icons-octicon "nf-oct-project" :face 'dashboard-button-face) " ")
                           "📁 "))
               (label (format "%s (%s)" name abbrev-dir-str))
               (proj-btn (let ((map (make-sparse-keymap))
                               (path dir))
                           (define-key map [mouse-1] (lambda (e) (interactive "e")
                                                       (dashboard-splash-kill)
                                                       (let ((default-directory path))
                                                         (project-find-file))))
                           (define-key map [mouse-2] (lambda (e) (interactive "e")
                                                       (dashboard-splash-kill)
                                                       (let ((default-directory path))
                                                         (project-find-file))))
                           (define-key map [?\r] (lambda () (interactive)
                                                   (dashboard-splash-kill)
                                                   (let ((default-directory path))
                                                     (project-find-file))))
                           (define-key map (kbd "RET") (lambda () (interactive)
                                                         (dashboard-splash-kill)
                                                         (let ((default-directory path))
                                                           (project-find-file))))
                           (define-key map [follow-link] 'mouse-face)
                            (propertize label
                                        'face 'dashboard-button-face
                                        'mouse-face 'highlight
                                        'follow-link t
                                        'keymap map
                                       'help-echo (format "Open project %s" name)))))
          (push (concat "  " icon-str proj-btn) lines)))
      (dashboard--card "Recent Projects" (nreverse lines) :icon "🗂️"))))

(defun dashboard--roam-actions-section ()
  "Insert org-roam quick actions card."
  (let* ((roam-actions
          (list
           (list "c" "Create Note" #'dashboard-create-roam-note)
           (list "s" "Search Note" #'dashboard-find-roam-node)
           (list "d" "Daily Note" #'dashboard-roam-daily)
           (list "g" "Open Graph" #'dashboard-roam-ui)
           (list "b" "Toggle Sidebar" #'dashboard-sidebar-toggle)))
         (lines
          (mapcar (lambda (act)
                    (let ((key (nth 0 act))
                          (label (nth 1 act))
                          (func (nth 2 act)))
                      (concat "  " (dashboard-make-button-string
                                    (format "[%s] %s" key label) func))))
                  roam-actions)))
    (dashboard--card "Org-roam Quick Actions" lines :icon "🔗")))

(defun dashboard--recent-roam-notes-section ()
  "Insert recent roam notes card."
  (let* ((roam-notes nil)
         (lines nil))
    (when (and (fboundp 'org-roam-db-query)
               (boundp 'org-roam-directory)
               org-roam-directory
               (file-directory-p org-roam-directory))
      (condition-case nil
          (setq roam-notes
                (org-roam-db-query
                 "SELECT title, file FROM nodes JOIN files ON nodes.file = files.file ORDER BY files.mtime DESC LIMIT 8"))
        (error nil)))
    (if (not roam-notes)
        (setq lines (list (propertize "  No Roam notes found" 'face 'theme-face-faded)))
      (dolist (note roam-notes)
        (let* ((title (car note))
               (file (cadr note))
               (note-btn (dashboard-make-file-button-string title file (format "Open %s" title)))
               (icon-str (if (and (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
                             (concat (nerd-icons-icon-for-file file) " ")
                           (concat (dashboard-make-icon-string "bx-edit") " "))))
          (push (concat "  " icon-str note-btn) lines)))
      (setq lines (nreverse lines)))
    (dashboard--card "Recent Roam Notes" lines :icon "bx-edit")))

(defun dashboard--bookmarks-section ()
  "Insert bookmarks card."
  (let* ((bookmarks (and (boundp 'bookmark-alist) bookmark-alist))
         (max-bookmarks 8)
         (bookmark-items (and bookmarks (cl-subseq bookmarks 0 (min max-bookmarks (length bookmarks)))))
         (lines nil))
    (if (not bookmark-items)
        (setq lines (list (propertize "  No bookmarks found" 'face 'theme-face-faded)))
      (dolist (bm bookmark-items)
        (let* ((name (car bm))
               (bm-btn (let ((map (make-sparse-keymap))
                             (bm-name name))
                         (define-key map [mouse-1] (lambda (e) (interactive "e")
                                                     (dashboard-splash-kill)
                                                     (bookmark-jump bm-name)))
                         (define-key map [mouse-2] (lambda (e) (interactive "e")
                                                     (dashboard-splash-kill)
                                                     (bookmark-jump bm-name)))
                         (define-key map [?\r] (lambda () (interactive)
                                                 (dashboard-splash-kill)
                                                 (bookmark-jump bm-name)))
                         (define-key map (kbd "RET") (lambda () (interactive)
                                                       (dashboard-splash-kill)
                                                       (bookmark-jump bm-name)))
                         (define-key map [follow-link] 'mouse-face)
                          (propertize name
                                      'face 'dashboard-button-face
                                      'mouse-face 'highlight
                                      'follow-link t
                                      'keymap map
                                     'help-echo (format "Jump to bookmark %s" name))))
               (icon-str (if (and (fboundp 'nerd-icons-octicon) (display-graphic-p))
                             (concat (nerd-icons-octicon "nf-oct-bookmark" :face 'dashboard-button-face) " ")
                           "🔖 ")))
          (push (concat "  " icon-str bm-btn) lines)))
      (setq lines (nreverse lines)))
    (dashboard--card "Bookmarks" lines :icon "🔖")))

(defun dashboard--footer-section ()
  "Insert the three-column footer: Quick Actions | Org-roam | Get Things Done."
  (let* ((box-width 80)
         (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
         (actions
          (list
           (list "f" "Find File" #'dashboard-find-file)
           (list "p" "Switch Project" #'dashboard-project-switch)
           (list "e" "Explorer" #'neotree-toggle)
            (list "q" "Quit Emacs" #'dashboard-exit)))
         (roam-actions
          (list
           (list "c" "Create Note" #'dashboard-create-roam-note)
           (list "s" "Search Note" #'dashboard-find-roam-node)
           (list "d" "Daily Note" #'dashboard-roam-daily)
           (list "g" "Open Graph" #'dashboard-roam-ui)
           (list "b" "Toggle Sidebar" #'dashboard-sidebar-toggle)))
         (org-dirs (list (expand-file-name "~/.orgfiles/")
                         (expand-file-name "~/Documents/Org/")))
         (org-files (cl-loop for dir in org-dirs
                             if (file-directory-p dir)
                             append (directory-files dir t "^[^.#].*\\.org$")))
         (max-notes 10)
         (note-items (and org-files (cl-subseq org-files 0 (min max-notes (length org-files)))))
         (col-width 23)
         (right-col-width 24)
         ;; format columns
         (left-rows
          (mapcar (lambda (act)
                    (let* ((key (nth 0 act))
                           (label (nth 1 act))
                           (func (nth 2 act))
                           (btn-str (dashboard-make-button-string
                                     (format "[%s] %s" key label) func)))
                      (dashboard-pad-to-width (concat "  " btn-str) col-width)))
                  actions))
         (middle-rows
          (mapcar (lambda (act)
                    (let* ((key (nth 0 act))
                           (label (nth 1 act))
                           (func (nth 2 act))
                           (btn-str (dashboard-make-button-string
                                     (format "[%s] %s" key label) func)))
                      (dashboard-pad-to-width (concat "  " btn-str) col-width)))
                  roam-actions))
         (right-rows
          (if (not note-items)
              (list (dashboard-pad-to-width (propertize "  No Org files" 'face 'theme-face-faded) right-col-width))
            (mapcar (lambda (note)
                       (let* ((raw-name (file-name-sans-extension (file-name-nondirectory note)))
                              (name (concat (upcase (substring raw-name 0 1)) (substring raw-name 1)))
                              (name-trunc (if (> (length name) 14)
                                              (concat (substring name 0 11) "...")
                                            name))
                              (note-btn (let ((map (make-sparse-keymap))
                                              (path note))
                                          (define-key map [mouse-1] (lambda (_e) (interactive "e")
                                                                     (find-alternate-file path)))
                                          (define-key map [mouse-2] (lambda (_e) (interactive "e")
                                                                     (find-alternate-file path)))
                                          (define-key map (kbd "RET") (lambda () (interactive)
                                                                       (find-alternate-file path)))
                                         (define-key map [follow-link] 'mouse-face)
                                          (propertize name-trunc
                                                      'face 'dashboard-button-face
                                                      'mouse-face 'highlight
                                                      'follow-link t
                                                      'keymap map
                                                      'help-echo (format "Open note %s" name))))
                             (icon-str (if (and (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
                                           (concat (nerd-icons-icon-for-file note) " ")
                                         (concat (dashboard-make-icon-string "bx-edit") " "))))
                        (dashboard-pad-to-width (concat "  " icon-str note-btn) right-col-width)))
                    note-items)))
         (max-rows (max (length left-rows) (length middle-rows) (length right-rows))))
    ;; top border with column headers
    (insert (make-string box-padding ?\s)
            (propertize "┌" 'face 'dashboard-border-face)
            (propertize (dashboard--border-title " Quick Actions " col-width) 'face 'dashboard-border-face)
            (propertize "┐" 'face 'dashboard-border-face)
            "  "
            (propertize "┌" 'face 'dashboard-border-face)
            (propertize (dashboard--border-title " Org-roam " col-width) 'face 'dashboard-border-face)
            (propertize "┐" 'face 'dashboard-border-face)
            "  "
            (propertize "┌" 'face 'dashboard-border-face)
            (propertize (dashboard--border-title " GET THINGS DONE " right-col-width) 'face 'dashboard-border-face)
            (propertize "┐" 'face 'dashboard-border-face)
            "\n")
     ;; body rows with full background fill
    (dotimes (i max-rows)
      (let ((left-str (if (< i (length left-rows))
                          (nth i left-rows)
                        (make-string col-width ?\s)))
            (middle-str (if (< i (length middle-rows))
                            (nth i middle-rows)
                          (make-string col-width ?\s)))
            (right-str (if (< i (length right-rows))
                           (nth i right-rows)
                         (make-string right-col-width ?\s)))
            (fmt-col (lambda (val w)
                       (concat (propertize "│" 'face 'dashboard-border-face)
                               (dashboard--fill-row val w)
                               (propertize "│" 'face 'dashboard-border-face)))))
        (insert (make-string box-padding ?\s)
                (funcall fmt-col left-str col-width)
                "  "
                (funcall fmt-col middle-str col-width)
                "  "
                (funcall fmt-col right-str right-col-width)
                "\n")))
    ;; bottom border
    (insert (make-string box-padding ?\s)
            (propertize "└" 'face 'dashboard-border-face)
            (propertize (make-string col-width ?─) 'face 'dashboard-border-face)
            (propertize "┘" 'face 'dashboard-border-face)
            "  "
            (propertize "└" 'face 'dashboard-border-face)
            (propertize (make-string col-width ?─) 'face 'dashboard-border-face)
            (propertize "┘" 'face 'dashboard-border-face)
            "  "
            (propertize "└" 'face 'dashboard-border-face)
            (propertize (make-string right-col-width ?─) 'face 'dashboard-border-face)
            (propertize "┘" 'face 'dashboard-border-face)
            "\n\n")))

(defun dashboard--border-title (title width)
  "Create a border line with TITLE centered in dashes."
  (let* ((clean (substring-no-properties title))
         (len (length clean))
         (total-dashes (- width len)))
    (if (<= total-dashes 0)
        (make-string width ?─)
      (let* ((left (/ total-dashes 2))
             (right (- total-dashes left)))
        (concat (make-string left ?─) clean (make-string right ?─))))))

(defun dashboard--keybindings-section ()
  "Insert a compact keybindings legend with which-key hint."
  (let* ((box-width 80)
         (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
         (cw 76)
         (fmt (lambda (key label &optional hint)
                (let ((kf (if hint 'theme-face-faded 'theme-face-faded))
                      (lf (if hint 'theme-face-default 'theme-face-default)))
                  (concat (propertize key 'face kf)
                          " " (propertize label 'face lf)))))
         (items (list (funcall fmt "SPC d d" "Home")
                      (funcall fmt "SPC f f" "Find")
                      (funcall fmt "SPC p p" "Project")
                      (funcall fmt "SPC t n" "Explorer")
                      (funcall fmt "q" "Quit")))
         (hint (funcall fmt "[?]" "Show all keys" t))
         ;; pack items into rows
         (rows (let (rows cur)
                 (dolist (s items)
                   (let ((len (length (substring-no-properties s))))
                     (if (and cur (< (+ (length (car cur)) len 2) cw))
                         (setcar cur (concat (car cur) "  " s))
                       (let ((cell (list s)))
                         (push cell rows)
                         (setq cur cell)))))
                 (nreverse rows))))
    (insert (make-string box-padding ?\s)
            (propertize "┌" 'face 'dashboard-border-face)
            (propertize (make-string 78 ?─) 'face 'dashboard-border-face)
            (propertize "┐" 'face 'dashboard-border-face)
            "\n")
    (dashboard--card-row (concat "  " (dashboard-make-icon-string "bx-keyboard") " Quick Keys") 76 box-padding)
    (insert (make-string box-padding ?\s)
            (propertize "├" 'face 'dashboard-border-face)
            (propertize (make-string 78 ?─) 'face 'dashboard-border-face)
            (propertize "┤" 'face 'dashboard-border-face)
            "\n")
    (dolist (cell rows)
      (dashboard--card-row (concat "  " (car cell)) 76 box-padding))
    (dashboard--card-row (concat "  " hint) 76 box-padding)
    (insert (make-string box-padding ?\s)
            (propertize "└" 'face 'dashboard-border-face)
            (propertize (make-string 78 ?─) 'face 'dashboard-border-face)
            (propertize "┘" 'face 'dashboard-border-face)
            "\n")))

(defun dashboard-splash (&optional force)
  "Bobamacs graphical dashboard with mascot, title, packages, and loading time.
If FORCE is non-nil, show the dashboard even if file buffers are open."
  (interactive "P")
  (unless dashboard-drawing-in-progress
    (let ((dashboard-drawing-in-progress t))
      (let* ((splash-buffer (get-buffer-create "*splash*"))
             (is-forced (or force
                            (with-current-buffer splash-buffer
                              (and (boundp 'dashboard-forced) dashboard-forced)))))
        (if (or is-forced
                (eq 0 (length (cl-loop for buf in (buffer-list)
                                       if (buffer-file-name buf)
                                       collect (buffer-file-name buf)))))
            (with-current-buffer splash-buffer
              (let ((inhibit-read-only t))
                (erase-buffer)
                (dashboard-mode)
                (setq-local cursor-type nil)
                (setq-local dashboard-forced is-forced)
                (cond
                 ((eq dashboard-current-page 'home)
                  ;; hero: mascot + BOBAMACS title + stats
                  (dashboard--hero-section)
                  ;; recent files
                  (dashboard--recent-files-section))
                 ((eq dashboard-current-page 'files)
                  (insert "\n\n")
                  (dashboard--recent-files-section)
                  (dashboard--recent-projects-section))
                 ((eq dashboard-current-page 'notes)
                  (insert "\n\n")
                  (dashboard--roam-actions-section)
                  (dashboard--recent-roam-notes-section)
                  (dashboard--bookmarks-section)))
                ;; footer (always shown)
                (dashboard--footer-section)
                ;; keybindings legend
                (dashboard--keybindings-section)
                (goto-char (point-min))
                (display-buffer-same-window splash-buffer nil)
                (run-with-idle-timer 0.05 nil (lambda () (message nil)))))
          (dashboard-splash-kill))))))

(defun center-string (string)
  "Pad a string with space on the left such as to center it."
  (let* ((padding (/ (- (window-body-width) (length string)) 2))
         (padding (+ (length string) padding)))
    (if (and tooltip-mode (fboundp 'x-show-tip))
        string
      (format (format "%%%ds" padding) string))))

(defvar mac-animation-locked-p nil)
(defun mac-animation-toggle-lock ()
  (setq mac-animation-locked-p (not mac-animation-locked-p)))

(defun mac-animation-fade-out (duration &rest args)
  (unless mac-animation-locked-p
    (mac-animation-toggle-lock)
    (mac-start-animation nil :type 'fade-out :duration duration)
    (run-with-timer duration nil 'mac-animation-toggle-lock)))

(defun dashboard-splash-fade-out (duration)
  (interactive)
  (defalias 'mac-animation-fade-out-local
    (apply-partially 'mac-animation-fade-out duration))
  (if (get-buffer "*splash*")
      (progn (if (and (display-graphic-p) (fboundp 'mac-start-animation))
                 (advice-add 'set-window-buffer :before 'mac-animation-fade-out-local))
             (message nil)
             (kill-buffer "*splash*")
             (if (and (display-graphic-p) (fboundp 'mac-start-animation))
                 (advice-remove 'set-window-buffer 'mac-animation-fade-out-local)))))

(defun dashboard-splash-fade-out-slow ()
  (interactive) (dashboard-splash-fade-out 1.00))

(defun dashboard-splash-kill ()
  (interactive)
  (if (get-buffer "*splash*")
      (progn (message nil)
             (cancel-function-timers 'dashboard-splash-fade-out-slow)
             (kill-buffer "*splash*"))))

(defvar-local dashboard-exit-active nil
  "Non-nil when the exit confirmation menu is shown.")

(defvar dashboard--quit-in-progress nil
  "Non-nil when a quit action has been confirmed, to avoid recursion.")

(defvar dashboard--quit-return-buffer nil
  "Buffer to return to on cancel from the global exit menu.")

(defun dashboard--exit-menu ()
  "Render the exit confirmation card.  Switch to splash buffer if needed."
  (let ((buf (get-buffer-create "*splash*")))
    (unless (eq (current-buffer) buf)
      (setq dashboard--quit-return-buffer (current-buffer))
      (switch-to-buffer buf))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (dashboard-mode)
      (setq dashboard-exit-active t)
      (dashboard--hero-section)
      (let* ((card-width 80)
             (cw (- card-width 4))
             (prompt (propertize "  Are you sure you want to quit?" 'face 'dashboard-stats-face))
             (row (concat "  "
                          (dashboard-make-button-string "[s] Save & Quit"
                                                        (lambda () (interactive)
                                                          (let ((dashboard--quit-in-progress t))
                                                            (save-some-buffers t)
                                                            (kill-emacs))))
                          "       "
                          (dashboard-make-button-string "[q] Quit Emacs"
                                                        (lambda () (interactive)
                                                          (let ((dashboard--quit-in-progress t))
                                                            (kill-emacs))))
                          "       "
                          (dashboard-make-button-string "[c] Cancel" 'dashboard-exit-cancel)))
             (spacer ""))
        (dashboard--card "Exit Bobamacs"
                         (list prompt spacer row)
                         :icon "bx-x"))
      (goto-char (point-min)))))

(defun dashboard-exit ()
  "Show exit confirmation, or quit on second press."
  (interactive)
  (if dashboard-exit-active
      (kill-emacs)
    (dashboard--exit-menu)))

(defun dashboard-exit-cancel ()
  "Return to the dashboard or previous buffer from the exit menu."
  (interactive)
  (let ((return-buf dashboard--quit-return-buffer))
    (setq dashboard-exit-active nil)
    (setq dashboard--quit-return-buffer nil)
    (if (and return-buf
             (buffer-live-p return-buf)
             (not (eq return-buf (current-buffer))))
        (switch-to-buffer return-buf)
      (dashboard-splash))))

(defun dashboard-exit-save-quit ()
  "Save all buffers and quit Emacs."
  (interactive)
  (let ((dashboard--quit-in-progress t))
    (save-some-buffers t)
    (kill-emacs)))

;; Intercept all quit attempts to show the exit menu
(defun dashboard--exit-advice (orig-fn &rest args)
  "Intercept `save-buffers-kill-terminal' and show the exit menu."
  (unless dashboard--quit-in-progress
    (dashboard--exit-menu)))

(advice-add 'save-buffers-kill-terminal :around #'dashboard--exit-advice)

(defun dashboard-cmd-or-create ()
  "Create roam note, or cancel if in exit menu."
  (interactive)
  (if dashboard-exit-active
      (dashboard-exit-cancel)
    (dashboard-create-roam-note)))

(defun dashboard-cmd-or-search ()
  "Search roam node, or save & quit if in exit menu."
  (interactive)
  (if dashboard-exit-active
      (dashboard-exit-save-quit)
    (dashboard-find-roam-node)))

(if (and (not (member "-no-splash"  command-line-args))
         (not (member "--file"      command-line-args))
         (not (member "--insert"    command-line-args))
         (not (member "--find-file" command-line-args)))
    (progn
      (add-hook 'window-setup-hook 'dashboard-splash)
      (setq inhibit-startup-screen t
            inhibit-startup-message t
            inhibit-startup-echo-area-message t)))

(defun dashboard-initial-buffer ()
  (dashboard-splash)
  (get-buffer "*splash*"))

(setq initial-buffer-choice #'dashboard-initial-buffer)

(defun dashboard-on-resize (&optional frame)
  (let ((buf (get-buffer "*splash*")))
    (when (and buf
               (get-buffer-window buf t)
               (not dashboard-drawing-in-progress)
               (not dashboard-exit-active))
      (save-current-buffer
        (with-selected-window (get-buffer-window buf t)
          (dashboard-splash))))))

(add-hook 'window-size-change-functions #'dashboard-on-resize)
(add-hook 'window-configuration-change-hook #'dashboard-on-resize)

;;;###autoload
(defun boba-dashboard-open ()
  (interactive)
  (dashboard-splash t))

(provide 'ui/dashboard)
;;; dashboard.el ends here
