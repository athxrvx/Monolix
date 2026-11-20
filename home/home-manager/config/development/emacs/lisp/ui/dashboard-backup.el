;;; dashboard.el --- Atomic Emacs interactive dashboard -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'cl-lib)
(require 'ui/layout)
(require 'ui/defaults)
(require 'svg-lib nil t)
(require 'svg-icon nil t)

;; (declare-function boba-sidebar-toggle "ui/sidebar")  ; disabled
(declare-function mac-start-animation "mac-win" (&rest args) t)
(declare-function theme-toggle "ui/theme" () t)
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
  "Face used for dashboard buttons (removes default link purple).")

(defface dashboard-border-face
  '((t :inherit theme-face-faded))
  "Face used for dashboard card borders.")

(defface dashboard-title-face
  '((t :inherit theme-face-default :weight bold))
  "Face used for dashboard card titles.")

(define-button-type 'dashboard-button
  'face 'dashboard-button-face
  'mouse-face 'highlight
  'follow-link t)

(defvar-local dashboard-current-page 'home
  "Current active page on the dashboard ('home, \'files, \'notes).")

(defun dashboard-find-file ()
  "Kill dashboard and find file."
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'find-file)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-recent-file ()
  "Kill dashboard and show recent files."
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'consult-recent-file)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-project-switch ()
  "Kill dashboard and switch project."
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'project-switch-project)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-create-roam-note ()
  "Kill dashboard and run org-roam-capture to create/capture a note."
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'org-roam-capture)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-find-roam-node ()
  "Kill dashboard and run org-roam-node-find to search/open a node."
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'org-roam-node-find)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-roam-daily ()
  "Kill dashboard and open today's daily note."
  (interactive)
  (let ((dashboard-buf (get-buffer "*splash*")))
    (call-interactively #'org-roam-dailies-goto-today)
    (when (and dashboard-buf
               (buffer-live-p dashboard-buf)
               (not (eq (current-buffer) dashboard-buf)))
      (kill-buffer dashboard-buf))))

(defun dashboard-roam-ui ()
  "Toggle org-roam-ui mode."
  (interactive)
  (call-interactively #'org-roam-ui-mode))

(defun dashboard-sidebar-toggle ()
  "Toggle the org backlinks sidebar."
  (interactive)
  (call-interactively #'boba-sidebar-toggle-org))

(defvar dashboard-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Interactive commands
    (define-key map (kbd "q") #'dashboard-splash-kill)
    (define-key map (kbd "e") #'neotree-toggle)
    (define-key map (kbd "f") #'dashboard-find-file)
    (define-key map (kbd "r") #'dashboard-recent-file)
    (define-key map (kbd "p") #'dashboard-project-switch)
    (define-key map (kbd "t") #'theme-toggle)
    (define-key map (kbd "c") #'dashboard-create-roam-note)
    (define-key map (kbd "s") #'dashboard-find-roam-node)
    (define-key map (kbd "d") #'dashboard-roam-daily)
    (define-key map (kbd "g") #'dashboard-roam-ui)
    (define-key map (kbd "b") #'dashboard-sidebar-toggle)
    ;; Page switching
    (define-key map (kbd "1") #'dashboard-switch-to-home)
    (define-key map (kbd "h") #'dashboard-switch-to-home)
    (define-key map (kbd "2") #'dashboard-switch-to-files)
    (define-key map (kbd "l") #'dashboard-switch-to-files)
    (define-key map (kbd "3") #'dashboard-switch-to-notes)
    (define-key map (kbd "n") #'dashboard-switch-to-notes)
    ;; Vim/Emacs standard navigation
    (define-key map (kbd "j") #'next-line)
    (define-key map (kbd "k") #'previous-line)
    (define-key map (kbd "RET") #'push-button)
    map)
  "Keymap for `dashboard-mode'.")

(with-eval-after-load 'evil
  (eval
   '(progn
      (evil-make-overriding-map dashboard-mode-map 'normal)
      (evil-make-overriding-map dashboard-mode-map 'motion)
      (evil-define-key 'normal dashboard-mode-map
        (kbd "q") #'dashboard-splash-kill
        (kbd "e") #'neotree-toggle
        (kbd "f") #'dashboard-find-file
        (kbd "r") #'dashboard-recent-file
        (kbd "p") #'dashboard-project-switch
        (kbd "t") #'theme-toggle
        (kbd "c") #'dashboard-create-roam-note
        (kbd "s") #'dashboard-find-roam-node
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
        (kbd "RET") #'push-button)
      (evil-define-key 'motion dashboard-mode-map
        (kbd "q") #'dashboard-splash-kill
        (kbd "e") #'neotree-toggle
        (kbd "f") #'dashboard-find-file
        (kbd "r") #'dashboard-recent-file
        (kbd "p") #'dashboard-project-switch
        (kbd "t") #'theme-toggle
        (kbd "c") #'dashboard-create-roam-note
        (kbd "s") #'dashboard-find-roam-node
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
        (kbd "RET") #'push-button))))

(define-derived-mode dashboard-mode special-mode "Dashboard"
  "Major mode for the Atomic Emacs dashboard.
Provides keyboard shortcuts for common actions and navigation."
  (setq mode-name "Dashboard")
  (setq cursor-type nil)
  (setq buffer-read-only t)
  (setq-local line-spacing 0)
  (setq-local header-line-format '(:eval (dashboard-header-line-format)))
  (setq-local vertical-scroll-bar nil)
  (setq-local horizontal-scroll-bar nil))

(defun dashboard-switch-page (page)
  "Switch the dashboard current page to PAGE ('home, 'files, 'notes) and redraw."
  (interactive)
  (when (member page '(home files notes))
    (setq dashboard-current-page page)
    (force-mode-line-update)
    (dashboard-splash)))

(defun dashboard-switch-to-home ()
  "Switch to the home page of the dashboard."
  (interactive)
  (dashboard-switch-page 'home))

(defun dashboard-switch-to-files ()
  "Switch to the files page of the dashboard."
  (interactive)
  (dashboard-switch-page 'files))

(defun dashboard-switch-to-notes ()
  "Switch to the notes page of the dashboard."
  (interactive)
  (dashboard-switch-page 'notes))

(defun dashboard-make-icon-string (icon-name &optional fg-color)
  "Create an icon string using boxicon ICON-NAME, optionally colored with FG-COLOR."
  (if (and (fboundp 'svg-icon) (display-graphic-p))
      (let* ((fg (or fg-color (face-foreground 'theme-face-salient nil 'default)))
             (bg (face-background 'default nil 'default))
             (icon (svg-icon "boxicons" icon-name fg bg 1.0)))
        (concat (propertize " " 'display icon) " "))
    ""))

(defun dashboard-make-tab-string (page label icon-name)
  "Create a clickable tab string for PAGE, displaying LABEL and boxicon ICON-NAME."
  (let* ((active (eq dashboard-current-page page))
         (fg-color (if active
                       (face-background 'default nil 'default)
                     (face-foreground 'theme-face-faded nil 'default)))
         (bg-color (if active
                       (face-foreground 'theme-face-salient nil 'default)
                     (face-background 'default nil 'default)))
         (icon (when (and (fboundp 'svg-icon) (display-graphic-p))
                 (svg-icon "boxicons" icon-name fg-color bg-color 1.2)))
         (tag (if icon
                  (concat (propertize " " 'display icon)
                          (propertize (concat " " label " ")
                                      'face `(:foreground ,fg-color :background ,bg-color :weight bold)))
                (propertize (concat " " label " ")
                            'face `(:foreground ,fg-color :background ,bg-color :weight bold)))))
    (propertize tag
                'pointer 'hand
                'help-echo (format "Switch to %s page" label)
                'keymap (let ((map (make-sparse-keymap)))
                          (define-key map [header-line mouse-1]
                            (let ((p page))
                              (lambda (e) (interactive "e") (dashboard-switch-page p))))
                          map))))

(defun dashboard-header-line-format ()
  "Generate the centered header-line format containing the dashboard tabs."
  (let* ((home-tab (dashboard-make-tab-string 'home "Home" "home"))
         (files-tab (dashboard-make-tab-string 'files "Files" "folder-open"))
         (notes-tab (dashboard-make-tab-string 'notes "Notes" "notepad"))
         (tabs-str (concat home-tab "   " files-tab "   " notes-tab))
         (has-icons (and (fboundp 'svg-icon) (display-graphic-p)))
         (visual-width (if has-icons 32 26))
         (padding (max 0 (/ (- (window-body-width) visual-width) 2))))
    (concat (make-string padding ?\s) tabs-str)))

(defvar dashboard-drawing-in-progress nil
  "Non-nil if dashboard drawing is currently in progress.")

(defun dashboard-insert-centered (text &optional face)
  "Insert TEXT centered in the window, optionally with FACE."
  (let* ((clean-text (substring-no-properties text))
         (len (length clean-text))
         (padding (max 0 (/ (- (window-body-width) len) 2))))
    (insert (make-string padding ?\s)
            (if face (propertize text 'face face) text)
            "\n")))

(defun dashboard-pad-to-width (text width)
  "Pad TEXT with spaces to be exactly WIDTH characters long, ignoring properties."
  (let* ((clean (substring-no-properties text))
         (len (length clean)))
    (if (>= len width)
        text
      (concat text (make-string (- width len) ?\s)))))

(defun dashboard-center-in-width (text width)
  "Center TEXT in a field of WIDTH characters, ignoring properties."
  (let* ((clean-text (substring-no-properties text))
         (len (length clean-text))
         (total-pad (- width len))
         (left-pad (/ total-pad 2))
         (right-pad (- total-pad left-pad)))
    (concat (make-string (max 0 left-pad) ?\s)
            text
            (make-string (max 0 right-pad) ?\s))))

(defun dashboard-border-title-string (title width)
  "Format a TITLE embedded in a box border line of WIDTH (excluding corners)."
  (let* ((clean-title (substring-no-properties title))
         (len (length clean-title))
         (total-dashes (- width len 2))) ; 2 for space padding
    (if (<= total-dashes 0)
        (make-string width ?─)
      (let* ((left-dashes (/ total-dashes 2))
             (right-dashes (- total-dashes left-dashes)))
        (concat (make-string left-dashes ?─)
                " " title " "
                (make-string right-dashes ?─))))))

(defun dashboard-abbrev-path (path max-len)
  "Abbreviate PATH to fit within MAX-LEN characters."
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
  "Create a button string that calls FUNC when clicked."
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
  "Create a button string that opens PATH when clicked."
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

(defun dashboard-splash (&optional force)
  "Atomic Emacs interactive dashboard with mascot, package stats, and recent files.
If FORCE is non-nil, show the dashboard even if file buffers are open."
  (interactive "P")
  (unless dashboard-drawing-in-progress
    (let ((dashboard-drawing-in-progress t))
      (let* ((splash-buffer  (get-buffer-create "*splash*"))
             (is-forced (or force
                            (with-current-buffer splash-buffer
                              (and (boundp 'dashboard-forced) dashboard-forced)))))

        ;; Only show splash screen if there are no opened file buffers (or if forced)
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

                ;; 1. Top padding
                (insert "\n\n")

                (cond
                 ;; ==================== HOME PAGE ====================
                 ((eq dashboard-current-page 'home)
                  ;; 2. Mascot Image (centered) or ASCII art
                  (if (and (display-graphic-p)
                           (file-exists-p (expand-file-name "dashboard_mascot.png" user-emacs-directory)))
                      (let* ((image-path (expand-file-name "dashboard_mascot.png" user-emacs-directory))
                             (img (create-image image-path nil nil :max-height 250 :max-width 250)))
                        (when img
                          (let ((padding (max 0 (/ (- (window-body-width) 32) 2)))) ; approx cols width for 250px img
                            (insert (make-string padding ?\s)))
                          (insert-image img)
                          (insert "\n\n")))
                    ;; Terminal ASCII Art
                    (dolist (line dashboard-ascii-logo)
                      (let ((padding (max 0 (/ (- (window-body-width) (length line)) 2))))
                        (insert (make-string padding ?\s)
                                (propertize line 'face 'theme-face-salient)
                                "\n")))
                    (insert "\n"))

                  ;; 3. Welcome Message & Package Stats Card (width 80)
                  (let* ((pkg-count (cond
                                     ((fboundp 'straight--build-dir)
                                      (length (directory-files (straight--build-dir) nil "^[^.]")))
                                     ((bound-and-true-p straight--activated-packages)
                                      (hash-table-count straight--activated-packages))
                                     ((boundp 'package-activated-list)
                                      (length package-activated-list))
                                     (t 0)))
                         (init-time (emacs-init-time))
                         (welcome-title (format "Welcome to Bobamacs %s" emacs-version))
                         (stats-str (format "%d packages loaded in %s" pkg-count init-time))
                         (box-width 80)
                         (box-padding (max 0 (/ (- (window-body-width) box-width) 2))))
                    ;; Top border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                            "\n")
                    ;; Spacing row
                    (insert (make-string box-padding ?\s)
                            (propertize "│ " 'face 'dashboard-border-face)
                            (make-string 76 ?\s)
                            (propertize " │" 'face 'dashboard-border-face)
                            "\n")
                    ;; Title row
                    (let ((title-centered (dashboard-center-in-width (propertize welcome-title 'face 'dashboard-title-face) 76)))
                      (insert (make-string box-padding ?\s)
                              (propertize "│ " 'face 'dashboard-border-face)
                              title-centered
                              (propertize " │" 'face 'dashboard-border-face)
                              "\n"))
                    ;; Stats row
                    (let ((stats-centered (dashboard-center-in-width (propertize stats-str 'face 'theme-face-faded) 76)))
                      (insert (make-string box-padding ?\s)
                              (propertize "│ " 'face 'dashboard-border-face)
                              stats-centered
                              (propertize " │" 'face 'dashboard-border-face)
                              "\n"))
                    ;; Spacing row
                    (insert (make-string box-padding ?\s)
                            (propertize "│ " 'face 'dashboard-border-face)
                            (make-string 76 ?\s)
                            (propertize " │" 'face 'dashboard-border-face)
                            "\n")
                    ;; Bottom border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                            "\n\n"))



                  ;; 5. Random Quote / Tip (Centered)
                  (let* ((quotes '("Who the hell uses VIM anyway? Go Evil!"
                                   "Atomic Emacs: Minimalist base, powerful core."
                                   "Keep your hands on the home row, and let Evil do the rest."
                                   "The editor of a lifetime."
                                   "Talk is cheap. Show me the code. — Linus Torvalds"
                                   "Simplicity is the ultimate sophistication. — Leonardo da Vinci"))
                         (random-quote (nth (random (length quotes)) quotes)))
                    (insert "\n")
                    (dashboard-insert-centered (concat "“ " random-quote " ”") 'theme-face-faded)
                    (insert "\n")))

                 ;; ==================== FILES PAGE ====================
                 ((eq dashboard-current-page 'files)
                  ;; Recent Files Card (width 80)
                  (let* ((box-width 80)
                         (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
                         (files (and (bound-and-true-p recentf-mode) recentf-list))
                         (max-files 10)
                         (file-items (and files (cl-subseq files 0 (min max-files (length files))))))
                    ;; Top border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                            "\n")
                    ;; Title
                    (let ((title-str (propertize "Recent Files" 'face 'dashboard-title-face)))
                      (insert (make-string box-padding ?\s)
                              (propertize "│ " 'face 'dashboard-border-face)
                              (dashboard-pad-to-width title-str 76)
                              (propertize " │" 'face 'dashboard-border-face)
                              "\n"))
                    ;; Separator
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "├" (make-string 78 ?─) "┤") 'face 'dashboard-border-face)
                            "\n")
                    ;; Rows
                    (if (not file-items)
                        (insert (make-string box-padding ?\s)
                                (propertize "│ " 'face 'dashboard-border-face)
                                (dashboard-pad-to-width (propertize "  No recent files" 'face 'theme-face-faded) 76)
                                (propertize " │" 'face 'dashboard-border-face)
                                "\n")
                      (dolist (f file-items)
                        (let* ((icon-str (if (and (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
                                             (concat (nerd-icons-icon-for-file f) " ")
                                           "• "))
                               (abbrev-path (dashboard-abbrev-path f 68))
                               (file-btn (dashboard-make-file-button-string abbrev-path f (format "Open %s" f)))
                               (row-str (concat "  " icon-str file-btn))
                               (row-padded (dashboard-pad-to-width row-str 76)))
                          (insert (make-string box-padding ?\s)
                                  (propertize "│ " 'face 'dashboard-border-face)
                                  row-padded
                                  (propertize " │" 'face 'dashboard-border-face)
                                  "\n"))))
                    ;; Bottom border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                            "\n\n"))

                  ;; Recent Projects Card (width 80)
                  (when (and (fboundp 'project-known-project-roots) (project-known-project-roots))
                    (let* ((projects (project-known-project-roots))
                           (max-proj 5)
                           (proj-items (cl-subseq projects 0 (min max-proj (length projects))))
                           (proj-width 80)
                           (proj-padding (max 0 (/ (- (window-body-width) proj-width) 2))))
                      ;; Top border
                      (insert (make-string proj-padding ?\s)
                              (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                              "\n")
                      ;; Title
                      (let ((title-str (propertize "Recent Projects" 'face 'dashboard-title-face)))
                        (insert (make-string proj-padding ?\s)
                                (propertize "│ " 'face 'dashboard-border-face)
                                (dashboard-pad-to-width title-str 76)
                                (propertize " │" 'face 'dashboard-border-face)
                                "\n"))
                      ;; Separator
                      (insert (make-string proj-padding ?\s)
                              (propertize (concat "├" (make-string 78 ?─) "┤") 'face 'dashboard-border-face)
                              "\n")
                      ;; Rows
                      (dolist (proj proj-items)
                        (let* ((dir (file-name-as-directory proj))
                               (name (file-name-nondirectory (directory-file-name dir)))
                               (abbrev-dir (abbreviate-file-name dir))
                               (max-dir-len (- 74 (length name) 6))
                               (abbrev-dir-str (if (> (length abbrev-dir) max-dir-len)
                                                   (concat "..." (substring abbrev-dir (- (length abbrev-dir) (- max-dir-len 3))))
                                                 abbrev-dir))
                               (icon-str (if (and (fboundp 'nerd-icons-octicon) (display-graphic-p))
                                             (concat (nerd-icons-octicon "nf-oct-project" :face 'dashboard-button-face) " ")
                                           "📂 "))
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
                                                       'help-echo (format "Open project %s" name))))
                               (row-str (concat icon-str proj-btn))
                               (row-padded (dashboard-pad-to-width row-str 76)))
                          (insert (make-string proj-padding ?\s)
                                  (propertize "│ " 'face 'dashboard-border-face)
                                  row-padded
                                  (propertize " │" 'face 'dashboard-border-face)
                                  "\n")))
                      ;; Bottom border
                      (insert (make-string proj-padding ?\s)
                              (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                              "\n\n"))))

                 ;; ==================== NOTES PAGE ====================
                 ((eq dashboard-current-page 'notes)
                  ;; 1. Org-roam Quick Actions Card (width 80)
                  (let* ((box-width 80)
                         (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
                         (roam-actions
                          (list
                           (list "c" "Create Note" #'dashboard-create-roam-note "edit")
                           (list "s" "Search Note" #'dashboard-find-roam-node "search")
                           (list "d" "Daily Note" #'dashboard-roam-daily "calendar")
                           (list "g" "Open Graph" #'dashboard-roam-ui "network-chart")
                           (list "b" "Toggle Sidebar" #'dashboard-sidebar-toggle "sidebar"))))
                    ;; Top border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                            "\n")
                    ;; Title
                    (let ((title-str (propertize "Org-roam Quick Actions" 'face 'dashboard-title-face)))
                      (insert (make-string box-padding ?\s)
                              (propertize "│ " 'face 'dashboard-border-face)
                              (dashboard-pad-to-width title-str 76)
                              (propertize " │" 'face 'dashboard-border-face)
                              "\n"))
                    ;; Separator
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "├" (make-string 78 ?─) "┤") 'face 'dashboard-border-face)
                            "\n")
                    ;; Rows
                    (dolist (act roam-actions)
                      (let* ((key (nth 0 act))
                             (label (nth 1 act))
                             (func (nth 2 act))
                             (icon (nth 3 act))
                             (icon-str (dashboard-make-icon-string icon))
                             (btn-label (format "[%s] %s" key label))
                             (btn-str (dashboard-make-button-string btn-label func (format "Trigger %s" label)))
                             (row-str (concat "  " icon-str btn-str))
                             (row-padded (dashboard-pad-to-width row-str 76)))
                        (insert (make-string box-padding ?\s)
                                (propertize "│ " 'face 'dashboard-border-face)
                                row-padded
                                (propertize " │" 'face 'dashboard-border-face)
                                "\n")))
                    ;; Bottom border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                            "\n\n"))

                  ;; 2. Org-roam Recent Notes Card (width 80)
                  (let* ((box-width 80)
                         (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
                         (roam-notes nil))
                    (when (and (fboundp 'org-roam-db-query)
                               (boundp 'org-roam-directory)
                               org-roam-directory
                               (file-directory-p org-roam-directory))
                      (condition-case nil
                          (setq roam-notes
                                (org-roam-db-query
                                 "SELECT title, file FROM nodes JOIN files ON nodes.file = files.file ORDER BY files.mtime DESC LIMIT 8"))
                        (error nil)))
                    ;; Top border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                            "\n")
                    ;; Title
                    (let ((title-str (propertize "Recent Roam Notes" 'face 'dashboard-title-face)))
                      (insert (make-string box-padding ?\s)
                              (propertize "│ " 'face 'dashboard-border-face)
                              (dashboard-pad-to-width title-str 76)
                              (propertize " │" 'face 'dashboard-border-face)
                              "\n"))
                    ;; Separator
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "├" (make-string 78 ?─) "┤") 'face 'dashboard-border-face)
                            "\n")
                    ;; Rows
                    (if (not roam-notes)
                        (insert (make-string box-padding ?\s)
                                (propertize "│ " 'face 'dashboard-border-face)
                                (dashboard-pad-to-width (propertize "  No Roam notes found (or database empty)" 'face 'theme-face-faded) 76)
                                (propertize " │" 'face 'dashboard-border-face)
                                "\n")
                      (dolist (note roam-notes)
                        (let* ((title (car note))
                               (file (cadr note))
                               (note-btn (dashboard-make-file-button-string title file (format "Open %s" title)))
                               (icon-str (if (and (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
                                             (concat (nerd-icons-icon-for-file file) " ")
                                           "📝 "))
                               (row-str (concat "  " icon-str note-btn))
                               (row-padded (dashboard-pad-to-width row-str 76)))
                          (insert (make-string box-padding ?\s)
                                  (propertize "│ " 'face 'dashboard-border-face)
                                  row-padded
                                  (propertize " │" 'face 'dashboard-border-face)
                                  "\n"))))
                    ;; Bottom border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                            "\n\n"))

                  ;; 3. Bookmarks Card (width 80)
                  (let* ((box-width 80)
                         (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
                         (bookmarks (and (boundp 'bookmark-alist) bookmark-alist))
                         (max-bookmarks 10)
                         (bookmark-items (and bookmarks (cl-subseq bookmarks 0 (min max-bookmarks (length bookmarks))))))
                    ;; Top border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                            "\n")
                    ;; Title
                    (let ((title-str (propertize "Bookmarks" 'face 'dashboard-title-face)))
                      (insert (make-string box-padding ?\s)
                              (propertize "│ " 'face 'dashboard-border-face)
                              (dashboard-pad-to-width title-str 76)
                              (propertize " │" 'face 'dashboard-border-face)
                              "\n"))
                    ;; Separator
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "├" (make-string 78 ?─) "┤") 'face 'dashboard-border-face)
                            "\n")
                    ;; Rows
                    (if (not bookmark-items)
                        (insert (make-string box-padding ?\s)
                                (propertize "│ " 'face 'dashboard-border-face)
                                (dashboard-pad-to-width (propertize "  No bookmarks found" 'face 'theme-face-faded) 76)
                                (propertize " │" 'face 'dashboard-border-face)
                                "\n")
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
                                         (propertize bm-name
                                                     'face 'dashboard-button-face
                                                     'mouse-face 'highlight
                                                     'follow-link t
                                                     'keymap map
                                                     'help-echo (format "Jump to bookmark %s" bm-name))))
                               (icon-str (if (and (fboundp 'nerd-icons-octicon) (display-graphic-p))
                                             (concat (nerd-icons-octicon "nf-oct-bookmark" :face 'dashboard-button-face) " ")
                                           "🔖 "))
                               (row-str (concat "  " icon-str bm-btn))
                               (row-padded (dashboard-pad-to-width row-str 76)))
                          (insert (make-string box-padding ?\s)
                                  (propertize "│ " 'face 'dashboard-border-face)
                                  row-padded
                                  (propertize " │" 'face 'dashboard-border-face)
                                  "\n"))))
                    ;; Bottom border
                    (insert (make-string box-padding ?\s)
                            (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                            "\n\n"))))

                ;; ==================== ALWAYS SHOW: QUICK ACTIONS & GET THINGS DONE ====================
                (let* ((box-width 80)
                       (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
                       ;; Quick Actions
                       (actions
                        (list
                         (list "f" "Find File" #'dashboard-find-file "search")
                         (list "p" "Switch Project" #'dashboard-project-switch "folder")
                         (list "e" "Explorer" #'neotree-toggle "sidebar")
                         (list "t" "Toggle Theme" #'theme-toggle "palette")
                         (list "q" "Quit Emacs" #'save-buffers-kill-terminal "log-out")))
                       ;; Org-roam Actions
                       (roam-actions
                        (list
                         (list "c" "Create Note" #'dashboard-create-roam-note "edit")
                         (list "s" "Search Note" #'dashboard-find-roam-node "search")
                         (list "d" "Daily Note" #'dashboard-roam-daily "calendar")
                         (list "g" "Open Graph" #'dashboard-roam-ui "network-chart")
                         (list "b" "Toggle Sidebar" #'dashboard-sidebar-toggle "sidebar")))
                       ;; Org Files (support both standard orgfiles and new Documents/Org directory)
                       (org-dirs (list (expand-file-name "~/.orgfiles/")
                                       (expand-file-name "~/Documents/Org/")))
                       (org-files (cl-loop for dir in org-dirs
                                           if (file-directory-p dir)
                                           append (directory-files dir t "^[^.#].*\\.org$")))
                       (max-notes 10)
                       (note-items (and org-files (cl-subseq org-files 0 (min max-notes (length org-files)))))
                       ;; Column settings
                       (has-svg (and (fboundp 'svg-icon) (display-graphic-p)))
                       (left-col-content-width 23)
                       (middle-col-content-width 23)
                       (right-col-content-width 24)
                       ;; Format left rows (Quick Actions)
                       (left-rows
                        (mapcar (lambda (act)
                                  (let* ((key (nth 0 act))
                                         (label (nth 1 act))
                                         (func (nth 2 act))
                                         (icon (nth 3 act))
                                         (icon-str (dashboard-make-icon-string icon))
                                         (btn-label (format "[%s] %s" key label))
                                         (btn-str (dashboard-make-button-string btn-label func (format "Trigger %s" label)))
                                         (row-str (concat "  " icon-str btn-str)))
                                    (dashboard-pad-to-width row-str left-col-content-width)))
                                actions))
                       ;; Format middle rows (Org-roam)
                       (middle-rows
                        (mapcar (lambda (act)
                                  (let* ((key (nth 0 act))
                                         (label (nth 1 act))
                                         (func (nth 2 act))
                                         (icon (nth 3 act))
                                         (icon-str (dashboard-make-icon-string icon))
                                         (btn-label (format "[%s] %s" key label))
                                         (btn-str (dashboard-make-button-string btn-label func (format "Trigger %s" label)))
                                         (row-str (concat "  " icon-str btn-str)))
                                    (dashboard-pad-to-width row-str middle-col-content-width)))
                                roam-actions))
                       ;; Format right rows (GET THINGS DONE)
                       (right-rows
                        (if (not note-items)
                            (list (dashboard-pad-to-width (propertize "  No Org files found" 'face 'theme-face-faded) right-col-content-width))
                          (mapcar (lambda (note)
                                    (let* ((name (file-name-nondirectory note))
                                           (name-truncated (if (> (length name) 16)
                                                               (concat (substring name 0 13) "...")
                                                             name))
                                           (note-btn (let ((map (make-sparse-keymap))
                                                           (path note))
                                                       (define-key map [mouse-1] (lambda (e) (interactive "e")
                                                                                   (dashboard-splash-kill)
                                                                                   (find-file path)))
                                                       (define-key map [mouse-2] (lambda (e) (interactive "e")
                                                                                   (dashboard-splash-kill)
                                                                                   (find-file path)))
                                                       (define-key map [?\r] (lambda () (interactive)
                                                                               (dashboard-splash-kill)
                                                                               (find-file path)))
                                                       (define-key map (kbd "RET") (lambda () (interactive)
                                                                                     (dashboard-splash-kill)
                                                                                     (find-file path)))
                                                       (define-key map [follow-link] 'mouse-face)
                                                       (propertize name-truncated
                                                                   'face 'dashboard-button-face
                                                                   'mouse-face 'highlight
                                                                   'follow-link t
                                                                   'keymap map
                                                                   'help-echo (format "Open note %s" name))))
                                           (icon-str (if (and (fboundp 'nerd-icons-icon-for-file) (display-graphic-p))
                                                         (concat (nerd-icons-icon-for-file note) " ")
                                                       "📝 "))
                                           (row-str (concat "  " icon-str note-btn)))
                                      (dashboard-pad-to-width row-str right-col-content-width)))
                                  note-items)))
                       ;; Headers
                       (left-header (dashboard-border-title-string "Quick Actions" left-col-content-width))
                       (middle-header (dashboard-border-title-string "Org-roam" middle-col-content-width))
                       (right-header (dashboard-border-title-string "GET THINGS DONE" right-col-content-width))
                       ;; Top & Bottom lines
                       (top-line (concat (propertize "╭" 'face 'dashboard-border-face)
                                         (propertize left-header 'face 'dashboard-border-face)
                                         (propertize "╮" 'face 'dashboard-border-face)
                                         "  "
                                         (propertize "╭" 'face 'dashboard-border-face)
                                         (propertize middle-header 'face 'dashboard-border-face)
                                         (propertize "╮" 'face 'dashboard-border-face)
                                         "  "
                                         (propertize "╭" 'face 'dashboard-border-face)
                                         (propertize right-header 'face 'dashboard-border-face)
                                         (propertize "╮" 'face 'dashboard-border-face)))
                       (bottom-line (concat (propertize "╰" 'face 'dashboard-border-face)
                                            (propertize (make-string left-col-content-width ?─) 'face 'dashboard-border-face)
                                            (propertize "╯" 'face 'dashboard-border-face)
                                            "  "
                                            (propertize "╰" 'face 'dashboard-border-face)
                                            (propertize (make-string middle-col-content-width ?─) 'face 'dashboard-border-face)
                                            (propertize "╯" 'face 'dashboard-border-face)
                                            "  "
                                            (propertize "╰" 'face 'dashboard-border-face)
                                            (propertize (make-string right-col-content-width ?─) 'face 'dashboard-border-face)
                                            (propertize "╯" 'face 'dashboard-border-face)))
                       (max-rows (max (length left-rows) (length middle-rows) (length right-rows))))
                  ;; Insert top border
                  (insert (make-string box-padding ?\s) top-line "\n")
                  ;; Insert body rows
                  (dotimes (i max-rows)
                    (let* ((left-val (if (< i (length left-rows))
                                         (nth i left-rows)
                                       (make-string left-col-content-width ?\s)))
                           (middle-val (if (< i (length middle-rows))
                                           (nth i middle-rows)
                                         (make-string middle-col-content-width ?\s)))
                           (right-val (if (< i (length right-rows))
                                          (nth i right-rows)
                                        (make-string right-col-content-width ?\s)))
                           (row-line (concat (propertize "│" 'face 'dashboard-border-face)
                                             left-val
                                             (propertize "│" 'face 'dashboard-border-face)
                                             "  "
                                             (propertize "│" 'face 'dashboard-border-face)
                                             middle-val
                                             (propertize "│" 'face 'dashboard-border-face)
                                             "  "
                                             (propertize "│" 'face 'dashboard-border-face)
                                             right-val
                                             (propertize "│" 'face 'dashboard-border-face))))
                      (insert (make-string box-padding ?\s) row-line "\n")))
                  ;; Insert bottom border
                  (insert (make-string box-padding ?\s) bottom-line "\n\n"))

                ;; Spacing for Keyboard Legend
                (let* ((footer-height 8) ; height of keybindings card + spacing
                       (current-line (line-number-at-pos))
                       (window-height (window-body-height))
                       ;; Account for mascot image height if in GUI mode (only on home page!)
                       (mascot-phantom-lines
                        (if (and (eq dashboard-current-page 'home)
                                 (display-graphic-p)
                                 (file-exists-p (expand-file-name "dashboard_mascot.png" user-emacs-directory)))
                            (let ((char-height (frame-char-height)))
                              (if (and char-height (> char-height 0))
                                  (- (/ 250 char-height) 1)
                                14)) ; fallback to 14 lines
                          0))
                       (needed-newlines (- window-height current-line footer-height mascot-phantom-lines)))
                  (when (> needed-newlines 0)
                    (insert (make-string needed-newlines ?\n))))

                ;; 6. Keyboard Legend (docked at bottom, wrapped in a beautiful Box)
                (let* ((box-width 80)
                       (box-padding (max 0 (/ (- (window-body-width) box-width) 2)))
                       ;; Formatting function
                       (fmt-item (lambda (key label &optional is-quit)
                                   (let ((key-face (if is-quit 'bold 'theme-face-faded))
                                          (label-face (if is-quit 'bold 'theme-face-default)))
                                     (concat (propertize (format "[%s]" key) 'face key-face)
                                             " "
                                             (propertize label 'face label-face)))))
                       ;; Left / Right items row 1
                       (left-r1 (concat (funcall fmt-item "1" "Home") "    "
                                        (funcall fmt-item "2" "Files") "    "
                                        (funcall fmt-item "3" "Notes")))
                       (right-r1 (funcall fmt-item "q" "Quit" t))
                       ;; Left / Right items row 2
                       (left-r2 (concat (funcall fmt-item "e" "Explorer") "    "
                                        (funcall fmt-item "t" "Toggle Theme") "    "
                                        (funcall fmt-item "c" "Create Note") "    "
                                        (funcall fmt-item "s" "Search Note")))
                       (right-r2 "")
                       ;; Lengths without properties to compute spacing
                       (len-l1 (length (substring-no-properties left-r1)))
                       (len-r1 (length (substring-no-properties right-r1)))
                       (len-l2 (length (substring-no-properties left-r2)))
                       (len-r2 (length (substring-no-properties right-r2)))
                       ;; Spacers inside the 76-width content area
                       (space-r1 (max 1 (- 76 len-l1 len-r1)))
                       (space-r2 (max 1 (- 76 len-l2 len-r2)))
                       ;; Content lines
                       (content-r1 (concat left-r1 (make-string space-r1 ?\s) right-r1))
                       (content-r2 (concat left-r2 (make-string space-r2 ?\s) right-r2)))
                  ;; Top border
                  (insert (make-string box-padding ?\s)
                          (propertize (concat "╭" (make-string 78 ?─) "╮") 'face 'dashboard-border-face)
                          "\n")
                  ;; Title row
                  (let ((title-str (propertize "Keybindings & Navigation" 'face 'dashboard-title-face)))
                    (insert (make-string box-padding ?\s)
                            (propertize "│ " 'face 'dashboard-border-face)
                            (dashboard-pad-to-width title-str 76)
                            (propertize " │" 'face 'dashboard-border-face)
                            "\n"))
                  ;; Separator
                  (insert (make-string box-padding ?\s)
                          (propertize (concat "├" (make-string 78 ?─) "┤") 'face 'dashboard-border-face)
                          "\n")
                  ;; Row 1
                  (insert (make-string box-padding ?\s)
                          (propertize "│ " 'face 'dashboard-border-face)
                          content-r1
                          (propertize " │" 'face 'dashboard-border-face)
                          "\n")
                  ;; Row 2
                  (insert (make-string box-padding ?\s)
                          (propertize "│ " 'face 'dashboard-border-face)
                          content-r2
                          (propertize " │" 'face 'dashboard-border-face)
                          "\n")
                  ;; Bottom border
                  (insert (make-string box-padding ?\s)
                          (propertize (concat "╰" (make-string 78 ?─) "╯") 'face 'dashboard-border-face)
                          "\n\n"))

                (goto-char (point-min))
                (display-buffer-same-window splash-buffer nil)
                (run-with-idle-timer 0.05 nil (lambda() (message nil)))))
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
  "Fade out current frame for duration and goes to command-or-buffer."
  (interactive)
  (defalias 'mac-animation-fade-out-local
    (apply-partially 'mac-animation-fade-out duration))
  (if (get-buffer "*splash*")
      (progn (if (and (display-graphic-p) (fboundp 'mac-start-animation))
                 (advice-add 'set-window-buffer
                              :before 'mac-animation-fade-out-local))
             (message nil)
             (kill-buffer "*splash*")
             (if (and (display-graphic-p) (fboundp 'mac-start-animation))
                 (advice-remove 'set-window-buffer
                                'mac-animation-fade-out-local)))))

(defun dashboard-splash-fade-out-slow ()
  (interactive) (dashboard-splash-fade-out 1.00))

(defun dashboard-splash-kill ()
  "Kill the splash screen buffer (immediately)."
  (interactive)
  (if (get-buffer "*splash*")
      (progn (message nil)
             (cancel-function-timers 'dashboard-splash-fade-out-slow)
             (kill-buffer "*splash*"))))

;; Install hook after frame parameters have been applied
(if (and (not (member "-no-splash"  command-line-args))
         (not (member "--file"      command-line-args))
         (not (member "--insert"    command-line-args))
         (not (member "--find-file" command-line-args)))
    (progn
      (add-hook 'window-setup-hook 'dashboard-splash)
      (setq inhibit-startup-screen t 
            inhibit-startup-message t
            inhibit-startup-echo-area-message t)))

;; Set dashboard as the initial buffer choice on startup
(defun dashboard-initial-buffer ()
  "Initialize the dashboard and return its buffer."
  (dashboard-splash)
  (get-buffer "*splash*"))

(setq initial-buffer-choice #'dashboard-initial-buffer)

(defun dashboard-on-resize (&optional frame)
  "Regenerate dashboard buffer when window/frame is resized."
  (let ((buf (get-buffer "*splash*")))
    (when (and buf
               (get-buffer-window buf t)
               (not dashboard-drawing-in-progress))
      (save-current-buffer
        (with-selected-window (get-buffer-window buf t)
          (dashboard-splash))))))

(add-hook 'window-size-change-functions #'dashboard-on-resize)
(add-hook 'window-configuration-change-hook #'dashboard-on-resize)

;;;###autoload
(defun boba-dashboard-open ()
  "Reopen the Boba dashboard buffer (*splash*)."
  (interactive)
  (dashboard-splash t))

(provide 'ui/dashboard)
;;; dashboard.el ends here
