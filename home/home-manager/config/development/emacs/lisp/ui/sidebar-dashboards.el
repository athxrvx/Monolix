;;; sidebar-dashboards.el --- Boba Sidebar Dashboards -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'ui/faces)

(defgroup boba-sidebar nil
  "Boba sidebar settings"
  :group 'nano)

(defvar boba-sidebar-habits-file (expand-file-name "habits.org" boba-data-dir))
(defvar boba-sidebar-todo-file (expand-file-name "todo.org" boba-data-dir))
(defvar boba-sidebar-projects-file (expand-file-name "projects.org" boba-data-dir))
(defvar boba-sidebar-notes-file (expand-file-name "notes.org" boba-data-dir))

(defvar boba-sidebar--inhibit-update nil
  "Inhibit recursive updates in boba sidebar hooks.")

;; ==========================================
;; Helper Utilities
;; ==========================================

(defun boba-sidebar--get-buffer-string (file-path)
  "Retrieve buffer string, using modified buffer if open, else reading file."
  (let ((buf (find-buffer-visiting file-path)))
    (if buf
        (with-current-buffer buf
          (buffer-substring-no-properties (point-min) (point-max)))
      (with-temp-buffer
        (when (file-exists-p file-path)
          (insert-file-contents file-path))
        (buffer-string)))))

(defun boba-sidebar--truncate-string (str max-len)
  "Truncate STR to MAX-LEN and append '…' if truncated."
  (if (and str (> (length str) max-len))
      (concat (substring str 0 (- max-len 1)) "…")
    str))

(defun boba-sidebar--make-progress-bar (percent width)
  "Create a Unicode progress bar representing PERCENT with WIDTH."
  (let* ((filled-chars (round (* (/ (float percent) 100.0) width)))
         (filled-chars (max 0 (min width filled-chars)))
         (empty-chars (- width filled-chars))
         (filled-bar (make-string filled-chars ?█))
         (empty-bar (make-string empty-chars ?░)))
    (concat "[" filled-bar empty-bar "]")))

(defun boba-sidebar-insert-section-header (title)
  "Insert a stylized section header with a horizontal line."
  (let* ((title-str (concat " " (upcase title) " "))
         (line-len (max 0 (- 32 (length title-str))))
         (line (make-string line-len ?─)))
    (insert (propertize title-str 'face 'boba-strong)
            (propertize line 'face 'boba-faded)
            "\n\n")))

(defvar boba-sidebar-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'boba-sidebar-activate-at-point)
    (define-key map (kbd "<mouse-1>") #'boba-sidebar-click-at-point)
    (define-key map (kbd "g") #'boba-sidebar-refresh-active)
    map)
  "Keymap for BOBA sidebar dashboards.")

(define-derived-mode boba-sidebar-dashboard-mode special-mode "Boba Dashboard"
  "Major mode for Boba Sidebar Dashboards."
  (setq buffer-read-only t)
  (setq cursor-type nil)
  (setq truncate-lines t)
  (setq-local word-wrap nil)
  (setq-local header-line-format nil)
  (visual-line-mode -1)
  (use-local-map boba-sidebar-mode-map))

(defun boba-sidebar-activate-at-point ()
  "Run the action associated with the item at point."
  (interactive)
  (let ((action (get-text-property (point) 'boba-sidebar-action)))
    (if action
        (funcall action)
      (message "No action at point."))))

(defun boba-sidebar-click-at-point (event)
  "Run the action at mouse click position."
  (interactive "e")
  (let ((pos (posn-point (event-start event))))
    (when pos
      (goto-char pos)
      (boba-sidebar-activate-at-point))))

(defun boba-sidebar-jump-to-item (file-path line-content)
  "Jump to LINE-CONTENT inside FILE-PATH."
  (let* ((sidebar-frame (selected-frame))
         (parent-frame (frame-parameter sidebar-frame 'parent-frame))
         (buf (find-file-noselect file-path)))
    (when parent-frame
      (select-frame-set-input-focus parent-frame))
    (let ((win (frame-selected-window parent-frame)))
      (select-window win)
      (switch-to-buffer buf)
      (goto-char (point-min))
      (if (search-forward line-content nil t)
          (progn
            (goto-char (match-beginning 0))
            (recenter))
        (message "Item not found in file: %s" line-content)))))

(defun boba-sidebar-toggle-checklist-item (file-path line-content current-checked)
  "Toggle checkbox state of checklist item in FILE-PATH."
  (let* ((buf (find-file-noselect file-path))
         (new-state (if current-checked " " "x")))
    (with-current-buffer buf
      (save-excursion
        (goto-char (point-min))
        (if (search-forward line-content nil t)
            (let ((line-start (line-beginning-position)))
              (goto-char line-start)
              (if (re-search-forward "\\[[ xX]\\]" (line-end-position) t)
                  (progn
                    (replace-match (format "[%s]" new-state) t t)
                    (save-buffer)
                    (message "Toggled checklist item!"))
                (message "No checkbox found on matched line.")))
          (message "Checklist item not found."))))
    (boba-sidebar-refresh-active)))

(defun boba-sidebar-refresh-active ()
  "Refresh the active Boba sidebar dashboard."
  (interactive)
  (let ((buf-name (buffer-name)))
    (cond
     ((string= buf-name "*Org Sidebar Habits*") (boba-sidebar-render-habits))
     ((string= buf-name "*Org Sidebar Todo*") (boba-sidebar-render-todo))
     ((string= buf-name "*Org Sidebar Projects*") (boba-sidebar-render-projects))
     ((string= buf-name "*Org Sidebar Notes*") (boba-sidebar-render-notes))
     ((string= buf-name "*Org Sidebar Roam*") (boba-sidebar-render-roam)))))

;; ==========================================
;; Add Operations
;; ==========================================

(defun boba-sidebar-add-todo ()
  "Prompt for a new task and add it to todo.org under Inbox."
  (interactive)
  (let ((title (read-string "New Task: ")))
    (when (and title (not (string-empty-p title)))
      (let ((buf (find-file-noselect boba-sidebar-todo-file)))
        (with-current-buffer buf
          (save-excursion
            (goto-char (point-min))
            (if (search-forward "* Inbox" nil t)
                (progn
                  (if (re-search-forward "^\\*" nil t)
                      (goto-char (line-beginning-position))
                    (goto-char (point-max)))
                  (insert (format "\n** TODO %s\n" title))
                  (save-buffer)
                  (message "Added task: %s" title))
              (message "Could not find '* Inbox' section in todo.org")))))
      (boba-sidebar-render-todo))))

(defun boba-sidebar-add-habit ()
  "Prompt for a new habit and add it to habits.org."
  (interactive)
  (let ((title (read-string "New Habit: ")))
    (when (and title (not (string-empty-p title)))
      (let ((buf (find-file-noselect boba-sidebar-habits-file))
            (today-str (format-time-string "%Y-%m-%d %a")))
        (with-current-buffer buf
          (save-excursion
            (goto-char (point-min))
            (if (search-forward "* Habits Tracker" nil t)
                (progn
                  (if (re-search-forward "^\\*" nil t)
                      (goto-char (line-beginning-position))
                    (goto-char (point-max)))
                  (insert (format "\n** TODO %s :habit:\n   SCHEDULED: <%s .+1d>\n   :PROPERTIES:\n   :STYLE:    habit\n   :END:\n" title today-str))
                  (save-buffer)
                  (message "Added habit: %s" title))
              (message "Could not find '* Habits Tracker' section in habits.org")))))
      (boba-sidebar-render-habits))))

(defun boba-sidebar-add-project ()
  "Prompt for a new project and add it to projects.org."
  (interactive)
  (let ((name (read-string "Project Name: "))
        (desc (read-string "Project Description: ")))
    (when (and name (not (string-empty-p name)))
      (let ((buf (find-file-noselect boba-sidebar-projects-file)))
        (with-current-buffer buf
          (save-excursion
            (goto-char (point-max))
            (insert (format "\n* Project %s :work:\n  Description: %s\n  Status: ACTIVE [0%%]\n" name desc))
            (save-buffer)
            (message "Added project: %s" name))))
      (boba-sidebar-render-projects))))

(defun boba-sidebar-add-note ()
  "Prompt for a new note and add it to notes.org under a category."
  (interactive)
  (let* ((content (boba-sidebar--get-buffer-string boba-sidebar-notes-file))
         (categories (mapcar #'car (boba-sidebar--parse-notes content)))
         (cat (completing-read "Category: " categories nil nil))
         (title (read-string "Note Title: ")))
    (when (and cat (not (string-empty-p cat)) title (not (string-empty-p title)))
      (let ((buf (find-file-noselect boba-sidebar-notes-file)))
        (with-current-buffer buf
          (save-excursion
            (goto-char (point-min))
            (if (search-forward (format "* %s" cat) nil t)
                (progn
                  (if (re-search-forward "^\\*" nil t)
                      (goto-char (line-beginning-position))
                    (goto-char (point-max)))
                  (insert (format "\n** %s\n   - [ ] Edit this note...\n" title))
                  (save-buffer)
                  (message "Added note: %s" title))
              (goto-char (point-max))
              (insert (format "\n* %s\n\n** %s\n   - [ ] Edit this note...\n" cat title))
              (save-buffer)
              (message "Created category '%s' and added note: %s" cat title)))))
      (boba-sidebar-render-notes))))

;; ==========================================
;; 1. Habits Dashboard
;; ==========================================

(defun boba-sidebar--parse-checklists (content)
  "Parse checklists under Daily Routines in habits content."
  (let ((routines nil)
        (current-routine nil)
        (in-routines nil)
        (lines (split-string content "\n")))
    (dolist (line lines)
      (cond
       ((string-match "^\\* \\(.*\\)$" line)
        (let ((sec-name (match-string 1 line)))
          (if (string-prefix-p "Daily Routines" sec-name)
              (setq in-routines t)
            (setq in-routines nil))))
       ((and in-routines (string-match "^\\*\\* \\(.*\\)$" line))
        (let ((name (match-string 1 line)))
          (setq current-routine (list name))
          (setq routines (cons current-routine routines))))
       ((and in-routines current-routine (string-match "^[ \t]*-[ \t]*\\[\\([ xX]\\)\\][ \t]*\\(.*\\)$" line))
        (let* ((checked (not (string= " " (match-string 1 line))))
               (text (match-string 2 line))
               (item (list text checked line)))
          (setcdr current-routine (append (cdr current-routine) (list item)))))))
    (nreverse routines)))

(defun boba-sidebar--parse-habits (content)
  "Parse habits from habits content."
  (let ((habits nil)
        (in-habits nil)
        (lines (split-string content "\n"))
        (i 0))
    (while (< i (length lines))
      (let ((line (nth i lines)))
        (cond
         ((string-match "^\\* \\(.*\\)$" line)
          (let ((sec-name (match-string 1 line)))
            (if (string-prefix-p "Habits Tracker" sec-name)
                (setq in-habits t)
              (setq in-habits nil))))
         ((and in-habits (string-match "^\\*\\* \\(?:TODO\\|DONE\\)?[ \t]*\\([^*:\n]+\\)\\(?:[ \t]+:habit:\\)?$" line))
          (let* ((title (string-trim (match-string 1 line)))
                 (last-repeat nil)
                 (scheduled nil))
            (setq i (1+ i))
            (while (and (< i (length lines))
                        (not (string-match "^\\*" (nth i lines))))
              (let ((subline (nth i lines)))
                (cond
                 ((string-match "SCHEDULED:[ \t]*<\\([^>]+\\)>" subline)
                  (setq scheduled (match-string 1 subline)))
                 ((string-match ":LAST_REPEAT:[ \t]*\\[\\([^]]+\\)\\]" subline)
                  (setq last-repeat (match-string 1 subline)))))
              (setq i (1+ i)))
            (setq i (1- i))
            (setq habits (cons (list title scheduled last-repeat line) habits)))))
        (setq i (1+ i))))
    (nreverse habits)))

(defun boba-sidebar-render-habits ()
  "Render the Habits dashboard buffer."
  (let* ((buf (get-buffer-create "*Org Sidebar Habits*"))
         (content (boba-sidebar--get-buffer-string boba-sidebar-habits-file))
         (routines (boba-sidebar--parse-checklists content))
         (habits (boba-sidebar--parse-habits content)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "\n")
        (insert (propertize "    HABITS TRACKER\n" 'face 'boba-strong))
        
        ;; Add button
        (insert "  ")
        (insert (propertize "[+] Add Habit"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Add a new habit to habits.org"
                            'boba-sidebar-action #'boba-sidebar-add-habit))
        (insert "\n")
        (insert (propertize "  ──────────────────────────────\n\n" 'face 'boba-faded))
        
        ;; 1. Checklists (Daily Routines)
        (boba-sidebar-insert-section-header "Daily Routines")
        (if (null routines)
            (insert (propertize "  No routines configured.\n\n" 'face 'boba-faded))
          (dolist (routine routines)
            (let ((name (car routine))
                  (items (cdr routine)))
              (insert (propertize (format "  %s\n" name) 'face 'boba-strong))
              (dolist (item items)
                (let* ((text (nth 0 item))
                       (checked (nth 1 item))
                       (orig-line (nth 2 item))
                       (box-str (if checked " [x] " " [ ] "))
                       (box-face (if checked 'boba-salient 'boba-faded))
                       (text-face (if checked 'boba-faded 'boba-default)))
                  (insert "   ")
                  ;; Clickable Checkbox
                  (insert (propertize box-str
                                      'face box-face
                                      'mouse-face 'highlight
                                      'help-echo "Click to toggle checklist state"
                                      'boba-sidebar-action (lambda () (boba-sidebar-toggle-checklist-item
                                                                       boba-sidebar-habits-file
                                                                       orig-line
                                                                       checked))))
                  ;; Clickable Title to jump to definition
                  (insert (propertize (boba-sidebar--truncate-string text 26)
                                      'face text-face
                                      'mouse-face 'highlight
                                      'help-echo "Jump to item in file"
                                      'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                       boba-sidebar-habits-file
                                                                       orig-line))))
                  (insert "\n")))
              (insert "\n"))))
        
        ;; 2. Habits
        (boba-sidebar-insert-section-header "Habits")
        (if (null habits)
            (insert (propertize "  No habits tracking.\n\n" 'face 'boba-faded))
          (dolist (habit habits)
            (let* ((title (nth 0 habit))
                   (sched (nth 1 habit))
                   (last-rep (nth 2 habit))
                   (orig-line (nth 3 habit))
                   ;; Determine status ring
                   (is-done (and sched (string-match "\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)" sched)
                                 (let* ((sched-date (match-string 1 sched))
                                        (today-str (format-time-string "%Y-%m-%d")))
                                   (string< today-str sched-date))))
                   (status-icon (if is-done "✓" "◔"))
                   (status-face (if is-done 'boba-salient 'boba-popout))
                   (streak-suffix (if last-rep " 🔥" ""))
                   (disp-title (boba-sidebar--truncate-string title (if last-rep 20 22)))
                   (dotted-len (max 2 (- 18 (+ (length disp-title) (length streak-suffix)))))
                   (dots (make-string dotted-len ?.)))
              (insert "  ")
              (insert (propertize disp-title
                                  'face 'boba-default
                                  'mouse-face 'highlight
                                  'help-echo "Jump to habit in file"
                                  'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                   boba-sidebar-habits-file
                                                                   orig-line))))
              (when last-rep
                (insert (propertize streak-suffix 'face 'boba-popout)))
              (insert (propertize dots 'face 'boba-faded) " ")
              (insert (propertize status-icon 'face status-face))
              (insert "\n"))))
        
        (insert "\n")
        (boba-sidebar-insert-section-header "Trend Sparkline")
        (insert "  Coding       ▁▂▃▄▅▆▇█\n")
        (insert "  Reading      █▇▆▅▄▃▂▁\n")
        
        (boba-sidebar-dashboard-mode)))))

;; ==========================================
;; 2. Todo Dashboard
;; ==========================================

(defun boba-sidebar--parse-todos (content)
  "Parse tasks from todo.org content."
  (let ((todos nil)
        (current-section nil)
        (lines (split-string content "\n")))
    (dolist (line lines)
      (cond
       ((string-match "^\\* \\([^*:\n]+\\)\\(?:[ \t]+:\\([a-zA-Z0-9_@:]+\\):\\)?$" line)
        (setq current-section (string-trim (match-string 1 line))))
       ((and current-section (string-match "^\\*\\* \\([A-Z]+\\)[ \t]+\\([^*:\n]+\\)\\(?:[ \t]+:\\([a-zA-Z0-9_@:]+\\):\\)?$" line))
        (let* ((keyword (match-string 1 line))
               (title (string-trim (match-string 2 line)))
               (tags (match-string 3 line))
               (item (list keyword title tags current-section line)))
          (setq todos (cons item todos))))))
    (nreverse todos)))

(defun boba-sidebar-render-todo ()
  "Render the Tasks dashboard buffer."
  (let* ((buf (get-buffer-create "*Org Sidebar Todo*"))
         (content (boba-sidebar--get-buffer-string boba-sidebar-todo-file))
         (todos (boba-sidebar--parse-todos content))
         (inbox-tasks (cl-remove-if-not (lambda (t-item) (string= (nth 3 t-item) "Inbox")) todos))
         (next-tasks (cl-remove-if-not (lambda (t-item) (string= (nth 0 t-item) "NEXT")) todos))
         (backlog-tasks (cl-remove-if-not (lambda (t-item) (string= (nth 3 t-item) "Backlog")) todos)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "\n")
        (insert (propertize "    TASKS INBOX\n" 'face 'boba-strong))
        
        ;; Add button
        (insert "  ")
        (insert (propertize "[+] Add Task"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Add a new task to todo.org"
                            'boba-sidebar-action #'boba-sidebar-add-todo))
        (insert "\n")
        (insert (propertize "  ──────────────────────────────\n\n" 'face 'boba-faded))
        
        ;; Status overview counts
        (boba-sidebar-insert-section-header "Eisenhower Snapshot")
        (let* ((inbox-len (length inbox-tasks))
               (next-len (length next-tasks))
               (back-len (length backlog-tasks))
               (dots-inbox (make-string (- 22 (length "Inbox Tasks")) ?.))
               (dots-focus (make-string (- 22 (length "Focus List")) ?.))
               (dots-back (make-string (- 22 (length "Backlog")) ?.)))
          (insert "  Focus List " (propertize dots-focus 'face 'boba-faded) " " (propertize (format "%02d" next-len) 'face 'boba-salient) "\n")
          (insert "  Inbox Tasks " (propertize dots-inbox 'face 'boba-faded) " " (propertize (format "%02d" inbox-len) 'face 'boba-popout) "\n")
          (insert "  Backlog " (propertize dots-back 'face 'boba-faded) " " (propertize (format "%02d" back-len) 'face 'boba-faded) "\n\n"))
        
        ;; Focus List (NEXT Actions)
        (boba-sidebar-insert-section-header "Focus List")
        (if (null next-tasks)
            (insert (propertize "  No focus tasks.\n\n" 'face 'boba-faded))
          (dolist (task next-tasks)
            (let ((title (nth 1 task))
                  (orig-line (nth 4 task)))
              (insert "  " (propertize "" 'face 'boba-salient) " ")
              (insert (propertize (boba-sidebar--truncate-string title 28)
                                  'face 'boba-default
                                  'mouse-face 'highlight
                                  'help-echo "Click to jump to task"
                                  'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                   boba-sidebar-todo-file
                                                                   orig-line))))
              (insert "\n")))
          (insert "\n"))
        
        ;; Inbox
        (boba-sidebar-insert-section-header "Inbox (Capture)")
        (if (null inbox-tasks)
            (insert (propertize "  Inbox empty.\n\n" 'face 'boba-faded))
          (dolist (task inbox-tasks)
            (let ((title (nth 1 task))
                  (orig-line (nth 4 task)))
              (insert "  " (propertize "" 'face 'boba-popout) " ")
              (insert (propertize (boba-sidebar--truncate-string title 28)
                                  'face 'boba-default
                                  'mouse-face 'highlight
                                  'help-echo "Click to jump to inbox task"
                                  'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                   boba-sidebar-todo-file
                                                                   orig-line))))
              (insert "\n")))
          (insert "\n"))
        
        (boba-sidebar-dashboard-mode)))))

;; ==========================================
;; 3. Projects Dashboard
;; ==========================================

(defun boba-sidebar--parse-projects (content)
  "Parse projects and their subtasks from projects content."
  (let ((projects nil)
        (current-project nil)
        (lines (split-string content "\n")))
    (dolist (line lines)
      (cond
       ((string-match "^\\* \\([^*:\n]+\\)\\(?:[ \t]+:\\([a-zA-Z0-9_@:]+\\):\\)?$" line)
        (let* ((name (string-trim (match-string 1 line)))
               (tags (match-string 2 line)))
          (setq current-project (list :name name :tags tags :desc "" :status "ACTIVE" :pct 0 :deadline nil :subtasks nil :line line))
          (setq projects (cons current-project projects))))
       
       (current-project
        (cond
         ((string-match "^[ \t]*Description:[ \t]*\\(.*\\)$" line)
          (setq current-project (plist-put current-project :desc (match-string 1 line))))
         ((string-match "^[ \t]*Status:[ \t]*\\([A-Z]+\\)\\(?:[ \t]*\\[\\([0-9]+\\)%\\]\\)?" line)
          (setq current-project (plist-put current-project :status (match-string 1 line)))
          (when (match-string 2 line)
            (setq current-project (plist-put current-project :pct (string-to-number (match-string 2 line))))))
         ((string-match "^[ \t]*Deadline:[ \t]*<\\([^>]+\\)>" line)
          (setq current-project (plist-put current-project :deadline (match-string 1 line))))
         ((string-match "^\\*\\* \\([A-Z]+\\)[ \t]+\\([^\n]+\\)$" line)
          (let* ((state (match-string 1 line))
                 (title (match-string 2 line))
                 (subtasks (plist-get current-project :subtasks)))
            (setq current-project (plist-put current-project :subtasks (append subtasks (list (list state title)))))))))))
    
    (dolist (p projects)
      (let* ((subtasks (plist-get p :subtasks))
             (total (length subtasks)))
        (when (> total 0)
          (let ((done-count (cl-count-if (lambda (s) (string= (car s) "DONE")) subtasks)))
            (setq p (plist-put p :pct (round (* (/ (float done-count) total) 100))))))))
    
    (nreverse projects)))

(defun boba-sidebar-render-projects ()
  "Render the Projects dashboard buffer."
  (let* ((buf (get-buffer-create "*Org Sidebar Projects*"))
         (content (boba-sidebar--get-buffer-string boba-sidebar-projects-file))
         (projects (boba-sidebar--parse-projects content)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "\n")
        (insert (propertize "    PROJECTS PORTFOLIO\n" 'face 'boba-strong))
        
        ;; Add button
        (insert "  ")
        (insert (propertize "[+] Add Project"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Add a new project to projects.org"
                            'boba-sidebar-action #'boba-sidebar-add-project))
        (insert "\n")
        (insert (propertize "  ──────────────────────────────\n\n" 'face 'boba-faded))
        
        (dolist (p projects)
          (let* ((name (plist-get p :name))
                 (tags (plist-get p :tags))
                 (desc (plist-get p :desc))
                 (pct (plist-get p :pct))
                 (deadline (plist-get p :deadline))
                 (orig-line (plist-get p :line))
                 ;; Strip 'Project ' prefix if present
                 (clean-name (if (string-prefix-p "project " (downcase name))
                                 (substring name 8)
                               name))
                 ;; Health color indicator
                 (health-circle (cond
                                 ((>= pct 70) "🟢")
                                 ((>= pct 30) "🟡")
                                 (t "🔴")))
                 (health-text (cond
                               ((>= pct 70) "Healthy")
                               ((>= pct 30) "At Risk")
                               (t "Pending")))
                 (health-face (cond
                               ((>= pct 70) 'boba-salient)
                               ((>= pct 30) 'boba-popout)
                               (t 'boba-critical))))
            
            ;; Clickable Project Title
            (insert "  " health-circle " ")
            (insert (propertize (boba-sidebar--truncate-string clean-name 22)
                                'face 'boba-strong
                                'mouse-face 'highlight
                                'help-echo "Click to jump to project"
                                'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                 boba-sidebar-projects-file
                                                                 orig-line))))
            (insert "\n")
            
            ;; Description (if set)
            (when (and desc (not (string-empty-p desc)))
              (insert "     " (propertize (boba-sidebar--truncate-string desc 28) 'face 'boba-faded) "\n"))
            
            ;; Progress Bar (narrower width 12 to fit form factor)
            (insert "     " (propertize (boba-sidebar--make-progress-bar pct 12) 'face 'boba-salient) " ")
            (insert (propertize (format "%3d%%" pct) 'face 'boba-strong) "\n")
            
            ;; Metadata (health, tags, short deadline in single line)
            (let ((meta-parts nil))
              (push (propertize health-text 'face health-face) meta-parts)
              (when tags
                (push (propertize (concat ":" tags ":") 'face 'boba-faded) meta-parts))
              (when deadline
                (let ((short-date (if (string-match "\\([0-9]\\{2\\}-[0-9]\\{2\\}\\)" deadline)
                                      (match-string 1 deadline)
                                    deadline)))
                  (push (propertize (concat "📅 " short-date) 'face 'boba-faded) meta-parts)))
              (insert "     " (mapconcat #'identity (nreverse meta-parts) " • ") "\n"))
            (insert "\n")))
        
        (boba-sidebar-dashboard-mode)))))

;; ==========================================
;; 4. Notes Dashboard
;; ==========================================

(defun boba-sidebar--parse-notes (content)
  "Parse categories and notes from notes content."
  (let ((categories nil)
        (current-cat nil)
        (lines (split-string content "\n")))
    (dolist (line lines)
      (cond
       ((string-match "^\\* \\([^*:\n]+\\)\\(?:[ \t]+:\\([a-zA-Z0-9_@:]+\\):\\)?$" line)
        (let ((name (string-trim (match-string 1 line))))
          (setq current-cat (list name nil line))
          (setq categories (cons current-cat categories))))
       ((and current-cat (string-match "^\\*\\* \\([^*\n]+\\)$" line))
        (let* ((name (string-trim (match-string 1 line)))
               (notes (cadr current-cat)))
          (setcar (cdr current-cat) (append notes (list (list name line))))))))
    (nreverse categories)))

(defun boba-sidebar-render-notes ()
  "Render the Notes dashboard buffer."
  (let* ((buf (get-buffer-create "*Org Sidebar Notes*"))
         (content (boba-sidebar--get-buffer-string boba-sidebar-notes-file))
         (categories (boba-sidebar--parse-notes content)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "\n")
        (insert (propertize "    NOTES INDEX\n" 'face 'boba-strong))
        
        ;; Add button
        (insert "  ")
        (insert (propertize "[+] Add Note"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Add a new note to notes.org"
                            'boba-sidebar-action #'boba-sidebar-add-note))
        (insert "\n")
        (insert (propertize "  ──────────────────────────────\n\n" 'face 'boba-faded))
        
        (dolist (cat categories)
          (let* ((cat-name (car cat))
                 (notes (cadr cat))
                 (orig-line (nth 2 cat))
                 (disp-cat (boba-sidebar--truncate-string cat-name 24)))
            
            ;; Clickable Category Header
            (insert " ")
            (insert (propertize (concat " " (upcase disp-cat) " ")
                                'face 'boba-strong
                                'mouse-face 'highlight
                                'help-echo "Click to jump to category heading"
                                'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                 boba-sidebar-notes-file
                                                                 orig-line))))
            (let* ((line-len (max 0 (- 31 (length disp-cat))))
                   (line (make-string line-len ?─)))
              (insert (propertize line 'face 'boba-faded) "\n\n"))
            
            (if (null notes)
                (insert (propertize "  No notes in category.\n\n" 'face 'boba-faded))
              (dolist (note notes)
                (let ((note-name (car note))
                      (note-line (cadr note)))
                  (insert "  " (propertize "" 'face 'boba-faded) " ")
                  (insert (propertize (boba-sidebar--truncate-string note-name 28)
                                      'face 'boba-default
                                      'mouse-face 'highlight
                                      'help-echo "Click to jump to note"
                                      'boba-sidebar-action (lambda () (boba-sidebar-jump-to-item
                                                                       boba-sidebar-notes-file
                                                                       note-line))))
                  (insert "\n")))
              (insert "\n"))))
        
        (boba-sidebar-dashboard-mode)))))

(defun boba-sidebar--get-parent-buffer ()
  "Get the active buffer in the main parent frame."
  (let* ((current-frame (selected-frame))
         (parent-frame (frame-parameter current-frame 'parent-frame))
         (buf (if parent-frame
                  ;; We are in the sidebar frame, look at parent frame
                  (window-buffer (frame-selected-window parent-frame))
                ;; We are in the parent frame already
                (current-buffer))))
    (if (or (null buf)
            (minibufferp buf)
            (string-prefix-p " *Minibuf" (buffer-name buf))
            (string-prefix-p "*Org Sidebar" (buffer-name buf))
            (string-equal (buffer-name buf) "*Org Sidebar Roam*")
            (string-equal (buffer-name buf) "BOBA sidebar"))
        (if (and (boundp 'boba-sidebar-last-global-buffer)
                 boba-sidebar-last-global-buffer
                 (buffer-live-p boba-sidebar-last-global-buffer))
            boba-sidebar-last-global-buffer
          buf)
      buf)))

(defun boba-sidebar--get-backlink-preview (backlink)
  "Get a line preview of where the backlink is located."
  (let* ((source-node (org-roam-backlink-source-node backlink))
         (file (org-roam-node-file source-node))
         (point (org-roam-backlink-point backlink)))
    (if (and file (file-exists-p file))
        (with-temp-buffer
          (insert-file-contents file)
          (goto-char point)
          (let ((line (string-trim (buffer-substring-no-properties
                                    (line-beginning-position)
                                    (line-end-position)))))
            ;; If the line is an org header, strip leading stars
            (if (string-prefix-p "*" line)
                (string-trim-left line "\\*+[ \t]*")
              line)))
      "")))

(defun boba-sidebar--get-outgoing-links (node)
  "Get list of outgoing org-roam nodes linked from NODE."
  (let ((node-id (and node (org-roam-node-id node))))
    (when (and node-id (fboundp 'org-roam-db-query))
      (let ((rows (org-roam-db-query
                   [:select dest
                    :from links
                    :where (= source $s1)
                    :and (= type "id")]
                   node-id)))
        (cl-loop for row in rows
                 for dest-id = (car row)
                 for dest-node = (org-roam-node-from-id dest-id)
                 if dest-node collect dest-node)))))

(defun boba-sidebar-jump-to-backlink (file point)
  "Open FILE in parent window and jump to POINT."
  (let* ((sidebar-frame (selected-frame))
         (parent-frame (frame-parameter sidebar-frame 'parent-frame))
         (buf (and file (find-file-noselect file))))
    (when (and parent-frame buf)
      (select-frame-set-input-focus parent-frame)
      (let ((win (frame-selected-window parent-frame)))
        (select-window win)
        (switch-to-buffer buf)
        (goto-char point)
        (recenter)))))

(defun boba-sidebar-jump-to-node (node)
  "Open NODE's file in the parent window."
  (let* ((sidebar-frame (selected-frame))
         (parent-frame (frame-parameter sidebar-frame 'parent-frame))
         (file (org-roam-node-file node))
         (point (org-roam-node-point node))
         (buf (and file (find-file-noselect file))))
    (when (and parent-frame buf)
      (select-frame-set-input-focus parent-frame)
      (let ((win (frame-selected-window parent-frame)))
        (select-window win)
        (switch-to-buffer buf)
        (goto-char (or point (point-min)))
        (recenter)))))

(defun boba-sidebar-convert-to-roam-note ()
  "Add ID to current file to register it as an Org-roam note."
  (interactive)
  (let ((parent-buf (boba-sidebar--get-parent-buffer)))
    (with-current-buffer parent-buf
      (org-id-get-create)
      (save-buffer)
      (message "Registered as Org-roam note!"))
    (boba-sidebar-refresh-active)))

(defun boba-sidebar-init-org-roam (_frame sidebar)
  "Sidebar initialization showing the unified Org-roam dashboard."
  (let* ((win (frame-selected-window sidebar))
         (buf (get-buffer-create "*Org Sidebar Roam*")))
    (set-window-dedicated-p win nil)
    (set-window-buffer win buf)
    (set-window-dedicated-p win t)
    (with-current-buffer buf
      (setq-local header-line-format nil)
      (setq-local mode-line-format nil)
      (hl-line-mode 1)
      (boba-sidebar-render-roam))))

(defun boba-sidebar-render-roam ()
  "Render the unified Org-roam dashboard buffer."
  (let* ((buf (get-buffer-create "*Org Sidebar Roam*"))
         (parent-buf (boba-sidebar--get-parent-buffer))
         (file-path (and parent-buf (buffer-file-name parent-buf)))
         (node (when (and file-path (fboundp 'org-roam-node-from-path))
                 (org-roam-node-from-path file-path)))
         (title (if node (org-roam-node-title node) (and parent-buf (buffer-name parent-buf))))
         (backlinks (when node (org-roam-backlinks-get node)))
         (outgoing (when node (boba-sidebar--get-outgoing-links node)))
         (recent-notes nil))

    ;; Fetch recent roam notes from database
    (when (and (fboundp 'org-roam-db-query)
               (boundp 'org-roam-directory)
               org-roam-directory
               (file-directory-p org-roam-directory))
      (condition-case nil
          (setq recent-notes
                (org-roam-db-query
                 "SELECT title, file FROM nodes JOIN files ON nodes.file = files.file ORDER BY files.mtime DESC LIMIT 5"))
        (error nil)))

    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "\n")
        (insert (propertize "    ROAM CONTROL PANEL\n" 'face 'boba-strong))
        
        ;; Add buttons for Graph, Capture, and Search Node
        (insert "  ")
        (insert (propertize "[f] Find"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Search Org-roam nodes"
                            'boba-sidebar-action #'org-roam-node-find))
        (insert "  ")
        (insert (propertize "[+] Capture"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Capture a new roam note"
                            'boba-sidebar-action #'org-roam-capture))
        (insert "  ")
        (insert (propertize "[o] Graph"
                            'face 'boba-salient
                            'mouse-face 'highlight
                            'help-echo "Open Org-roam graph visualizer in browser"
                            'boba-sidebar-action #'org-roam-ui-mode))
        (insert "\n")
        (insert (propertize "  ──────────────────────────────\n\n" 'face 'boba-faded))
        
        ;; Render current node info / backlinks / outgoing if visiting a roam node
        (if node
            (progn
              ;; Show current node metadata
              (insert "  " (propertize "Note: " 'face 'boba-faded))
              (insert (propertize (boba-sidebar--truncate-string title 24) 'face 'boba-strong) "\n")
              (when (org-roam-node-tags node)
                (insert "  " (propertize "Tags: " 'face 'boba-faded))
                (insert (propertize (mapconcat #'identity (org-roam-node-tags node) ", ") 'face 'boba-popout) "\n"))
              (insert "\n")

              ;; 1. Incoming links (Backlinks)
              (boba-sidebar-insert-section-header "Backlinks")
              (if (null backlinks)
                  (insert (propertize "  No incoming links.\n\n" 'face 'boba-faded))
                (dolist (backlink backlinks)
                  (let* ((source-node (org-roam-backlink-source-node backlink))
                         (source-title (org-roam-node-title source-node))
                         (source-file (org-roam-node-file source-node))
                         (point (org-roam-backlink-point backlink))
                         (preview (boba-sidebar--get-backlink-preview backlink)))
                    ;; Source node title link
                    (insert "  " (propertize "←" 'face 'boba-salient) " ")
                    (insert (propertize (boba-sidebar--truncate-string source-title 28)
                                        'face 'boba-strong
                                        'mouse-face 'highlight
                                        'help-echo "Jump to source note"
                                        'boba-sidebar-action (lambda () (boba-sidebar-jump-to-backlink source-file point))))
                    (insert "\n")
                    ;; Link context preview
                    (when (and preview (not (string-empty-p preview)))
                      (insert "    " (propertize (boba-sidebar--truncate-string preview 28) 'face 'boba-faded) "\n"))
                    (insert "\n"))))
              
              ;; 2. Outgoing links
              (boba-sidebar-insert-section-header "Outgoing Links")
              (if (null outgoing)
                  (insert (propertize "  No outgoing links.\n\n" 'face 'boba-faded))
                (dolist (dest-node outgoing)
                  (let ((dest-title (org-roam-node-title dest-node)))
                    (insert "  " (propertize "→" 'face 'boba-salient) " ")
                    (insert (propertize (boba-sidebar--truncate-string dest-title 28)
                                        'face 'boba-default
                                        'mouse-face 'highlight
                                        'help-echo "Open destination note"
                                        'boba-sidebar-action (lambda () (boba-sidebar-jump-to-node dest-node))))
                    (insert "\n"))))
              (insert "\n"))
          
          ;; If not visiting a registered roam note
          (boba-sidebar-insert-section-header "Not a Roam Note")
          (insert "  This buffer is not registered\n  in the Org-roam database.\n\n")
          (insert "  ")
          (insert (propertize "[*] Register as Note"
                              'face 'boba-popout
                              'mouse-face 'highlight
                              'help-echo "Add an ID to register this file with Org-roam"
                              'boba-sidebar-action #'boba-sidebar-convert-to-roam-note))
          (insert "\n\n"))

        ;; 3. Recent Roam Notes (always shown!)
        (boba-sidebar-insert-section-header "Recent Notes")
        (if (null recent-notes)
            (insert (propertize "  No recent notes found.\n\n" 'face 'boba-faded))
          (dolist (note recent-notes)
            (let* ((n-title (car note))
                   (n-file (cadr note))
                   (n-node (org-roam-node-from-path n-file)))
              (when n-node
                (insert "  " (propertize "•" 'face 'boba-salient) " ")
                (insert (propertize (boba-sidebar--truncate-string n-title 28)
                                    'face 'boba-default
                                    'mouse-face 'highlight
                                    'help-echo "Open note"
                                    'boba-sidebar-action (lambda () (boba-sidebar-jump-to-node n-node))))
                (insert "\n")))))
        (insert "\n")
        
        (boba-sidebar-dashboard-mode)))))

(provide 'ui/sidebar-dashboards)
