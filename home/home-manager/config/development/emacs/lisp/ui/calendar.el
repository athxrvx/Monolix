;;; calendar.el --- Nano calendar -*- lexical-binding: t -*-

;; Copyright (C) 2023-2025  Nicolas P. Rougier

;; Maintainer: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; URL: https://github.com/rougier/boba-calendar
;; Version: 1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package displays a calendar in the current buffer and allows
;; to select one or several dates.
;;

;;; Code
(require 'hl-line)
(require 'calendar)
(require 'holidays)
(require 'org-agenda)

(defgroup boba-calendar nil
  "Settings for nano calendar"
  :group 'applications)

(defgroup boba-calendar-faces nil
  "Faces"
  :group 'boba-calendar)

(defgroup boba-calendar-layout nil
  "Layout settings"
  :group 'boba-calendar)

(defcustom boba-calendar-layout '(3 . 4)
  "Calendar layout as (rows . columns)"
  :group 'boba-calendar-layout
  :type '(choice (const :tag "1x1" (1 . 1))
                 (const :tag "1x2" (1 . 2))
                 (const :tag "1x3" (1 . 3))
                 (const :tag "3x1" (3 . 1))
                 (const :tag "3x4" (3 . 4))
                 (const :tag "4x3" (4 . 3))
                 (const :tag "2x6" (2 . 6))
                 (const :tag "6x2" (6 . 2))))

(defcustom boba-calendar-org-agenda-keys "n"
  "Org-agenda key to use when showing org-agenda."
  :type 'string
  :group 'boba-calendar)
          
(defcustom boba-calendar-prefix "  "
  "String for prefixing lines"
  :type 'string
  :group 'boba-calendar-layout)

(defcustom boba-calendar-colsep "  "
  "String for separating columns"
  :type 'string
  :group 'boba-calendar-layout)

(defcustom boba-calendar-rowsep "\n"
  "String for separating rows"
  :type 'string
  :group 'boba-calendar-layout)

(defface boba-calendar-header-month-today
  `((t :inverse-video t :inherit (bold)))
  "Face for header month"
  :group 'boba-calendar-faces)

(defface boba-calendar-header-month-regular
  `((t :inherit (bold highlight)))
  "Face for header month"
  :group 'boba-calendar-faces)

(defface boba-calendar-header-weekday
  '((t :underline t
       :inherit (default)))
  "Face for header weekday"
  :group 'boba-calendar-faces)

(defface boba-calendar-header-weekend
  '((t :underline t
       :inherit (font-lock-comment-face)))
  "Face for header weekend"
  :group 'boba-calendar-faces)

(defface boba-calendar-weekday
  '((t :inherit (default)))
  "Face for week days"
  :group 'boba-calendar-faces)

(defface boba-calendar-weekend
  '((t :inherit (font-lock-comment-face)))
  "Face for week end"
  :group 'boba-calendar-faces)

(defface boba-calendar-holidays
  '((t :inherit (font-lock-comment-face)))
  "Face for holidays"
  :group 'boba-calendar-faces)

(defface boba-calendar-selected nil
  "Face for selected date"
  :group 'boba-calendar-faces)

(defface boba-calendar-workload-compact-free
  `((t :inherit (widget-field)))
  "Face for free slots on compact view."
  :group 'boba-calendar-faces)

(defface boba-calendar-workload-compact-busy
  `((t :inverse-video t
       :inherit (font-lock-comment-face)))
  "Face for busy slots on compact view."
  :group 'boba-calendar-faces)

(defface boba-calendar-workload-compact-overlap
  `((t :inverse-video t
       :foreground "#FF8A65"))
  "Face for overlapping slots on compact view."
  :group 'boba-calendar-faces)

(defface boba-calendar-today nil
  "Face for today"
  :group 'boba-calendar-faces)

(defcustom boba-calendar-workload-color t
  "Whether to show workload as background color."
  :type 'boolean
  :group 'boba-calendar)

(defcustom boba-calendar-workload-symbol nil
  "Whether to show workload as symbol next to day."
  :type 'boolean
  :group 'boba-calendar)

(defcustom boba-calendar-workload-detail nil
  "Whether to show workload detail in echo area."
  :type 'boolean
  :group 'boba-calendar)

(defcustom boba-calendar-workload-compact t
  "Whether to show workload compact form in echo area."
  :type 'boolean
  :group 'boba-calendar)

(defcustom boba-calendar-workload-alignment 'right
  "Whether to align worload left or right. Default is right"
  :type '(choice (const :tag "Left" left)
		 (const :tag "Right" right))
  :group 'boba-calendar)

(defcustom boba-calendar-workload-palette nil
  "List of (FG . BG) color pairs for Nano Calendar workload highlighting.
If nil, it will be dynamically derived based on the theme."
  :type '(repeat (cons color color))
  :group 'boba-calendar)

(defcustom boba-calendar-workload-symbols " ¹²³⁴⁵⁶⁷⁸⁹*"
  "String of workload symbols."
  :type 'string
  :group 'boba-calendar)
          
(defconst boba-calendar-buffer "*boba-calendar*"
  "Name of the buffer used for the calendar.")

(defvar boba-calendar--workload-cache nil
  "Cached list of (date workload) for internal use")

(defun boba-calendar--workload-get (date)
  "Search workload for DATE in cached workload."
  (or (alist-get date boba-calendar--workload-cache nil nil #'equal) 0))

(defun boba-calendar--workload-update-all ()
  "Computes the number of active timestamps per day, based on
all org agenda files."
  (setq boba-calendar--workload-cache nil)
  (message "Updating workload")
  (dolist (file (org-agenda-files))
    (with-current-buffer (find-file-noselect file)
      (org-with-wide-buffer
       (org-element-map (org-element-parse-buffer) 'timestamp
         #'boba-calendar--workload-parse)))))

(defun boba-calendar--workload-parse (timestamp)
  "This computes workload for the given TIMESTAMP (as generated
by org-element-parse-buffer) in order to add 1 to all days within the
start and end date of the timestamp of it is active."
  (when (memq (org-element-property :type timestamp) '(active active-range))
    (let* ((start-date
            (encode-time (list 0 0 0
                               (org-element-property :day-start timestamp)
                               (org-element-property :month-start timestamp)
                               (org-element-property :year-start timestamp))))
           (end-date
            (encode-time (list 0 0 0
                               (org-element-property :day-end timestamp)
                               (org-element-property :month-end timestamp)
                               (org-element-property :year-end timestamp))))
           (dates (let ((dates (list start-date)))
                    (while (time-less-p start-date end-date)
                      (setq start-date (time-add start-date (days-to-time 1)))
                      (setq dates (add-to-list 'dates start-date t)))
                    dates)))
      (dolist (date dates)
        (let* ((date (decode-time date))
               (date (list (nth 4 date) (nth 3 date) (nth 5 date))))
          (setf (alist-get date boba-calendar--workload-cache nil nil #'equal)
                (1+ (or (alist-get date boba-calendar--workload-cache
                                   nil nil #'equal) 0))))))))

(defun boba-calendar--workload-slots (date)
  "Compute 30-minute workload density slots for a given DATE from org agenda entries."
  (let ((files (org-agenda-files))
        (slots (make-list 48 0)))
    (dolist (file files)
      (dolist (entry (org-agenda-get-day-entries file date))
        (when-let* ((dt (get-text-property 0 'dotime entry))
                    (is-string (stringp dt)))
          (let* ((ts (substring-no-properties dt))
                 
                 ;; Parse start time
                 (start-parsed (org-parse-time-string ts))
                 (h-start (nth 2 start-parsed))
                 (m-start (nth 1 start-parsed))
                 
                 ;; Parse end time if present
                 (has-end (string-match "-\\([0-9]+\\):\\([0-9]+\\)" ts))
                 (h-end (if has-end
                            (string-to-number (match-string 1 ts))
                          h-start))
                 (m-end (if has-end
                            (string-to-number (match-string 2 ts))
                          (+ m-start 30))))

            ;; Normalize end minutes
            (when (>= m-end 60)
              (setq h-end (1+ h-end)
                    m-end (- m-end 60)))

            (let* ((start-min (+ (* h-start 60) m-start))
                   (end-min   (+ (* h-end 60) m-end))
                   (slot-start (/ start-min 30))
                   (slot-end   (/ end-min 30)))

              ;; Increment covered slots
              (dotimes (i 48)
                (when (and (>= i slot-start) (< i slot-end))
                  (setf (nth i slots)
                        (1+ (nth i slots))))))))))
    slots))

(defun boba-calendar-workload-compact (date &optional start-hour end-hour)
  "Return a compact representation of workload as 30-min half-hour blocks
per hour for DATE, between START-HOUR and END-HOUR."
  (let* ((timestamp (encode-time 0 0 0 (nth 1 date) (nth 0 date) (nth 2 date)))
         (date-str (format-time-string "%A %d %B %Y" timestamp))
         (slots (boba-calendar--workload-slots date))
         (start (or start-hour 8))
         (end   (or end-hour  18))
         (free    (propertize " " 'face 'boba-calendar-workload-compact-free))
         (busy    (propertize " " 'face 'boba-calendar-workload-compact-busy))
         (overlap (propertize " " 'face 'boba-calendar-workload-compact-overlap))
         (hours (mapcar (lambda (h) (format "%02d" h))
                        (number-sequence start end)))
         ;; extract the slots for the selected hours
         (hour-slots (cl-subseq slots (* 2 start) (* 2 (1+ end))))
         ;; group every 2 slots into 1 hour block with half-hour precision
         (blocks
          (cl-loop for i from 0 below (length hour-slots) by 2
                   for first  = (nth i hour-slots)
                   for second = (nth (1+ i) hour-slots)
                   for left =
                   (cond
                    ((= first 0) free)
                    ((= first 1) busy)
                    (t overlap))
                   for right =
                   (cond
                    ((= second 0) free)
                    ((= second 1) busy)
                    (t overlap))
                   collect (concat left right)))
         (line1 (concat
                  (propertize (format "%28s  " date-str) 'face 'bold)
                  (propertize (mapconcat #'identity hours " ")
                              'face 'font-lock-comment-face)))
         (line2 (concat
                  (propertize (format "%30s" "Free / Busy  ")
                              'face 'font-lock-comment-face)
                  (mapconcat #'identity blocks " ")))
         (space (make-string (max 0 (- (window-width)
                                       (length line1)
                                       (- left-margin-width)
                                       (- right-margin-width)
                                       1))
                             ?\s)))
    (if (eq boba-calendar-workload-alignment 'right)
        (concat space line1 "\n" space line2)
      (concat line1 "\n" line2))))

(defun boba-calendar-workload-update-all ()
  "Update all workloads"
  (interactive)
  (boba-calendar--workload-update-all)
  (boba-calendar-update))

(defun boba-calendar-workload-face (workload face)
  "Return the corresponding face for WORKLOAD given current FACE."
  (let* ((palette (or boba-calendar-workload-palette
                      (let* ((black (face-foreground 'default nil 'default))
                             (white (face-background 'default nil 'default)))
                        (list (cons black white)       ;; Base entry
                              ;; Material deep orange shades
                              (cons black "#FBE9E7")   ;; 50
                              (cons black "#FFCCBC")   ;; 100
                              (cons black "#FFAB91")   ;; 200
                              (cons black "#FF8A65")   ;; 300
                              (cons black "#FF7043")   ;; 400
                              (cons white "#FF5722")   ;; 500
                              (cons white "#F4511E")   ;; 600
                              (cons white "#E64A19")   ;; 700
                              (cons white "#D84315")   ;; 800
                              (cons white "#BF360C")))))
         (workload (min workload (1- (length palette)))))
    `( :foreground ,(car (nth workload palette))
       :background ,(cdr (nth workload palette)))))

(defun boba-calendar-workload-symbol (workload)
  "Return the corresponding symbol for WORKLOAD."
  (if boba-calendar-workload-symbol
      (let* ((symbols boba-calendar-workload-symbols)
             (workload (min workload (1- (length symbols)))))
        (substring symbols workload (1+ workload)))
    " "))

(defun boba-calendar--generate-day (day date is-today is-holidays is-weekend)
  "Internal function to generate a day number"
  (let* ((face (cond (is-today     'boba-calendar-today)
                     (is-holidays  'boba-calendar-holidays)
                     (is-weekend   'boba-calendar-weekend)
                     (t            'boba-calendar-weekday)))
         (workload (boba-calendar--workload-get date))
         (symbol (boba-calendar-workload-symbol workload))
         (face (cond (is-today 'boba-calendar-today)
                     ((eq workload 0) face)
                     (boba-calendar-workload-color
                      (boba-calendar-workload-face workload face))
                     (t face))))
    (propertize (format "%2d%s" day symbol)
                'date date
                'workload workload
                'is-today is-today
                'is-holidays is-holidays
                'is-weekend is-weekend
                'face face)))

(defun boba-calendar--collect--agenda-entries (date)
  "Retrieve org agenda entries for the given DATE."
  (let ((entries))
    (dolist (file (org-agenda-files))
      (dolist (entry (org-agenda-get-day-entries file date))
        (let* ((display (get-text-property 0 'display entry))
               (tags (get-text-property 0 'tags entry))
               (tags (mapconcat #'identity tags ","))
               (extra (string-trim (get-text-property 0 'extra entry)))
               (text (string-trim (get-text-property 0 'txt entry)))
               (text (replace-regexp-in-string (concat org-tsr-regexp " ") "" text))     
               (time (get-text-property 0 'time entry)))
          (unless (member "CANCELLED" (string-split tags ","))
            (push (concat
                   (propertize " " 'display display)
                   (concat
                    (unless (string-empty-p extra)
                      (concat (propertize extra
                                          'face 'default) " "))
                    (unless (or (string-empty-p time) (not (string-empty-p extra)))
                      (concat (propertize time
                                          'face 'bold) " - "))
                    (unless (string-empty-p text)
                      (concat (propertize (substring-no-properties text)
                                          'face 'default) " "))
                    (unless (string-empty-p tags)
                      (propertize tags 'face 'org-tag))))
                  entries)))))
    (sort entries #'string-lessp)))

(defun boba-calendar--generate-month (year month)
  "Generate the string representation of YEAR MONTH."
  (let* ((first (calendar-day-of-week (list month 1 year)))
         (first (+ (mod (+ (- first 1) 7) 7) 1)) ;; Week starts on Monday
         (last  (+ first (calendar-last-day-of-month month year)))
         (today (decode-time (current-time)))
         (is-today-month (and (= year (nth 5 today))
                              (= month (nth 4 today))))
         (face-today                'boba-calendar-today)
         (face-selected             'boba-calendar-selected)
         (face-holidays             'boba-calendar-holidays)
         (face-weekend              'boba-calendar-weekend)
         (face-weekday              'boba-calendar-weekday)
         (face-header-weekday       'boba-calendar-header-weekday)
         (face-header-weekend       'boba-calendar-header-weekend)
         (face-header-month-regular 'boba-calendar-header-month-regular) 
         (face-header-month-today   'boba-calendar-header-month-today)
         (face-header-month (if is-today-month
                                face-header-month-today
                              face-header-month-regular))
         (month-name (format "%s %d" (calendar-month-name month) year))
         ;; 20 = 7x3 -1 : This allow to privilege slightly left centering
         (month-padding (- 20 (length month-name)))
         (month-name (concat
                      (make-string (/ month-padding 2) ? )
                      month-name
                      (make-string (- month-padding (/ month-padding 2)) ? )))
         (month-name (concat (propertize month-name
                                         'font-lock-face face-header-month
                                         'face           face-header-month)
                             " "))
         (day-names (concat (propertize "Mo Tu We Th Fr "
                                         'font-lock-face face-header-weekday
                                         'face           face-header-weekday)
                            (propertize "Sa Su"
                                        'font-lock-face face-header-weekend
                                        'face           face-header-weekend)
                            " "))
         (output (concat month-name "\n"
                         day-names "\n")))
    (dotimes (row 6)
      (dotimes (col 7)
        (let* ((index (+ 1 col (* row 7)))
               (day (- index first -1))
               (date (list month day year))
               (is-holidays (calendar-check-holidays date))
               (is-today (and (= (nth 2 date) (nth 5 today))
                              (= (nth 0 date) (nth 4 today))
                              (= (nth 1 date) (nth 3 today))))
               (is-selected nil)
               (is-saturday (eq col 5))
               (is-sunday (eq col 6))
               (is-weekend (or is-saturday is-sunday))
               (face (cond (is-today     face-today)
                           (is-holidays  face-holidays)
                           (is-weekend   face-weekend)
                           (t            face-weekday))))
          (setq output
                (concat output 
                        (if (or (< index first) (>= index last))
                            "   "
                          (boba-calendar--generate-day day
                                                       date
                                                       is-today
                                                       is-holidays
                                                       is-weekend))))))
      (when (< row 5)
        (setq output (concat output "\n"))))
    output))
  
(defun boba-calendar--concat-months (months prefix separator)
  "Concatenate MONTHS, prefixes with PREFIX and separated by SEPARATOR."
  (let* ((lists (mapcar (lambda (month) (split-string month "\n")) months))
         (lines (apply #'cl-mapcar
                       (lambda (&rest parts)
                         (concat prefix (mapconcat #'identity parts separator)))
                       lists)))
    (mapconcat #'identity lines "\n")))

(defun boba-calendar--generate (&optional date layout)
  "Generate a calendar showing DATE and using specified LAYOUT."
  (let* ((layout (or layout boba-calendar-layout))
         (nrows (car layout))
         (ncols (cdr layout))
         (prefix boba-calendar-prefix)
         (colsep boba-calendar-colsep)
         (rowsep boba-calendar-rowsep)         
         (today (boba-calendar-today))
         (date-c (or date today))
         (date-1 (list 1 1 (nth 2 date-c)))
         (date-p (boba-calendar-date-add date-c '(0 -1 0)))
         (start (cond ((equal layout '(1 . 1)) date-c)
                      ((equal layout '(1 . 2)) date-c)
                      ((equal layout '(1 . 3)) date-p)
                      ((equal layout '(3 . 1)) date-p)
                      ((equal layout '(2 . 6)) date-1)
                      ((equal layout '(6 . 2)) date-1)
                      ((equal layout '(3 . 4)) date-1)
                      ((equal layout '(4 . 3)) date-1)
                      (t                       date-1)))
         (month (nth 0 start))
         (year  (nth 2 start))
         (months (let (result)
                    (dotimes (i (* nrows ncols) (nreverse result))
                      (push (boba-calendar--generate-month (+ year (/ (+ month i -1) 12))
                                                           (+ 1 (mod (+ month i -1) 12)))
                            result))))
         (chunks (seq-partition months ncols)))
    (mapconcat
     (lambda (batch)
       (boba-calendar--concat-months batch prefix colsep))
     chunks
     (concat "\n" rowsep))))

(defun boba-calendar-date-add (date delta)
  "Return a new DATE (month day year) adjusted by DELTA (day month year)."
  (calendar-gregorian-from-absolute
   (time-to-days
    (encode-time
     0 0 0
     (+ (nth 1 date) (nth 0 delta)) 
     (+ (nth 0 date) (nth 1 delta))
     (+ (nth 2 date) (nth 2 delta))))))

(defun boba-calendar-today ()
  "Return today date."
  (interactive)
  (let ((date (decode-time (current-time))))
    (list (nth 4 date) (nth 3 date) (nth 5 date))))

(defun boba-calendar-is-date-visible (date)
  "Return whether DATE is currently visible."
  (when-let ((buffer (get-buffer boba-calendar-buffer)))
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (text-property-search-forward 'date date t)))))

(defun boba-calendar-goto-date (date &optional redisplay)
  "Move point to the first character in the buffer whose 'date property equals DATE."
  (cond ((boba-calendar-is-date-visible date)
         (goto-char (point-min))
         (when-let ((match (text-property-search-forward 'date date t)))
           (goto-char (prop-match-beginning match))
           (force-mode-line-update)
           (when boba-calendar-workload-compact
             (boba-calendar-show-workload-compact))
           (when boba-calendar-workload-detail
             (boba-calendar-show-org-agenda-entries))
           t))
        (redisplay
         (boba-calendar-update date)
         (when boba-calendar-workload-compact
           (boba-calendar-show-workload-compact))
         (when boba-calendar-workload-detail
           (boba-calendar-show-org-agenda-entries))
         t)  
        (t nil)))

(defun boba-calendar-goto-relative-date (delta &optional redisplay)
  "Move point to date under cursor adjusted by DELTA."
  (let ((cursor-date (boba-calendar-cursor-date))
        (closest-date (boba-calendar-closest-date)))
    (cond (cursor-date
           (boba-calendar-goto-date 
            (boba-calendar-date-add cursor-date delta) redisplay))
          (closest-date
           (boba-calendar-goto-date closest-date redisplay))
          (t (message "No date under cursor")))))

(defun boba-calendar-cursor-date ()
  "Move cursor to today."
  (interactive)
  (get-text-property (point) 'date))

(defun boba-calendar-cursor-workload ()
  "Return workload for date under cursor."
  (interactive)
  (get-text-property (point) 'workload))

(defun boba-calendar-closest-date ()
  "Get point for closest date from cursor."
  (interactive)
  (let ((curr (get-text-property (point) 'date))
        (prev (save-excursion
                (text-property-search-backward 'date)
                (get-text-property (point) 'date)))
        (next (save-excursion
                (text-property-search-forward 'date)
                (when (> (point) (point-min))
                  (forward-char -1)
                  (get-text-property (point) 'date)))))
    (or curr prev next)))

(defun boba-calendar--hl-line-range ()
  "Return the start and end of the region that has the same `date` property at point."
  (save-match-data
    (save-excursion
      (if-let* ((date (get-text-property (point) 'date))
                (match (text-property-search-forward 'date date t))
                (beg (prop-match-beginning match))
                (end (prop-match-end match)))
          (cons beg end)
      (cons (point-min) (point-min))))))

(defun boba-calendar-goto-today ()
  "Move cursor to today."
  (interactive)
  (boba-calendar-goto-date (boba-calendar-today) t))

(defmacro boba-calendar-define-moves (&rest specs)
  "Macro to declare multiple boba-calendar navigation commands at once."
  `(progn
     ,@(mapcar
        (lambda (spec)
          (let ((name (nth 0 spec))
                (doc  (nth 1 spec))
                (args (nthcdr 2 spec)))
            `(defun ,name ()
               ,doc
               (interactive)
               (boba-calendar-goto-relative-date ,@args t))))
        specs)))

(boba-calendar-define-moves
  (boba-calendar-goto-prev-day  "Move cursor to previous day."  '(-1 0 0))
  (boba-calendar-goto-next-day  "Move cursor to next day."      '(+1 0 0))
  (boba-calendar-goto-prev-week "Move cursor to previous week."  '(-7 0 0))
  (boba-calendar-goto-next-week "Move cursor to next week."      '(+7 0 0))
  (boba-calendar-goto-prev-month "Move cursor to previous month." '(0 -1 0))
  (boba-calendar-goto-next-month "Move cursor to next month."     '(0 +1 0))
  (boba-calendar-goto-prev-year  "Move cursor to previous year."  '(0 0 -1))
  (boba-calendar-goto-next-year  "Move cursor to next year."      '(0 0 +1)))

(defun boba-calendar-quit ()
  "Bury calendar buffer."
  (interactive)
  (bury-buffer))

(defun boba-calendar-workload-menu ()
  "Toggle one of the mode flags via single key."
  (interactive)
  (let ((key (read-key (concat "Workload display:"
                               "   [b] background color"
                               "   [s] symbol"
                               "   [d] detail"
                               "   [c] compact"
                               )))
        (message-log-max nil))
    (pcase key
      (?b (setq boba-calendar-workload-color
                (not boba-calendar-workload-color))
          (boba-calendar-update))
      (?s (setq boba-calendar-workload-symbol
                (not boba-calendar-workload-symbol))
          (boba-calendar-update))
      (?c (setq boba-calendar-workload-compact
                (not boba-calendar-workload-compact))
          (boba-calendar-update))
      (?d (setq boba-calendar-workload-detail
                (not boba-calendar-workload-detail))
          (boba-calendar-update))
      (_ ))))

(defun boba-calendar-show-org-agenda-entries ()
  "Show agenda entries in echo area for current date."
  (interactive)
  (when-let* ((date (boba-calendar-cursor-date))
              (entries (boba-calendar--collect--agenda-entries date)))
    (let ((message-log-max nil))
      (message "%s" (mapconcat #'identity entries "\n")))))

(defun boba-calendar-show-workload-compact ()
  "Show compact workload in echo area for current date."
  (interactive)
  (when-let* ((date (boba-calendar-cursor-date)))
    (let ((message-log-max nil))
      (message (boba-calendar-workload-compact date)))))

(defun boba-calendar-goto-org-agenda ()
  "Go to org agenda for current DATE."
  (interactive)
  (when-let* ((date (boba-calendar-cursor-date))
              (year (nth 2 date))
              (month (nth 0 date))
              (day (nth 1 date))
              (date (format "%04d-%02d-%02d" year month day)))
    (boba-calendar-quit)
    (let ((org-agenda-start-day date))
      (org-agenda nil boba-calendar-org-agenda-keys))))

(define-minor-mode boba-calendar-mode
  "Nano calendar mode"
  :keymap  `((,(kbd "<left>")    . boba-calendar-goto-prev-day)
             (,(kbd "<right>")   . boba-calendar-goto-next-day)
             (,(kbd "<up>")      . boba-calendar-goto-prev-week)
             (,(kbd "<down>")    . boba-calendar-goto-next-week)
             (,(kbd "<S-left>")  . boba-calendar-goto-prev-month)
             (,(kbd "<S-right>") . boba-calendar-goto-next-month)
             (,(kbd "<S-down>")  . boba-calendar-goto-next-year)
             (,(kbd "<S-up>")    . boba-calendar-goto-prev-year)
             (,(kbd "v")         . boba-calendar-show-org-agenda-entries)
             (,(kbd "<RET>")     . boba-calendar-goto-org-agenda)
             (,(kbd "<SPC>")     . boba-calendar-show-org-agenda-entries)
             (,(kbd "w")         . boba-calendar-workload-menu)
             (,(kbd ".")         . boba-calendar-goto-today)
             (,(kbd "r")         . boba-calendar-workload-update-all)
             (,(kbd "q")         . boba-calendar-quit))
  (when boba-calendar-mode
    (setq-local hl-line-range-function #'boba-calendar--hl-line-range)
    (face-remap-set-base 'hl-line 'boba-calendar-selected)
    (hl-line-mode 1)
    (setq buffer-read-only t)))

(defun boba-calendar-update (&optional date)
  "Update calendar and workload."
  (let* ((buffer (get-buffer boba-calendar-buffer))
         (date (cond (date date)
                     ((buffer-live-p buffer)
                      (with-current-buffer buffer
                        (boba-calendar-closest-date)))
                     (t (boba-calendar-today))))
         (layout (or boba-calendar-layout)))
    (with-current-buffer buffer
      (when (or boba-calendar-workload-color
                boba-calendar-workload-detail
                boba-calendar-workload-compact
                boba-calendar-workload-symbol)
        (boba-calendar--workload-update-all))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (concat "\n" (boba-calendar--generate date layout) "\n")))
      (boba-calendar-goto-date date))))
  
;;;###autoload
(defun boba-calendar (&optional date)
  "Display a Gregorian calendar showing DATE and enforcing LAYOUT."
  (interactive)
  (if (and (buffer-live-p (get-buffer boba-calendar-buffer))
           (get-buffer-window boba-calendar-buffer))
      (delete-window (get-buffer-window boba-calendar-buffer))
    (if (buffer-live-p (get-buffer boba-calendar-buffer))
        (pop-to-buffer
         (get-buffer-create boba-calendar-buffer))
      (with-current-buffer (pop-to-buffer
                            (get-buffer-create boba-calendar-buffer))
        (let* ((date (if (not boba-calendar-mode)
                         (boba-calendar-today)
                       (boba-calendar-closest-date))))
          (boba-calendar-mode 1)
          (boba-calendar-update date)
          (fit-window-to-buffer nil nil (window-height))
          (recenter -1)
          (run-hooks 'boba-calendar-hook))))))

(defun my-update-calendar-colors ()
  "Update custom boba-calendar faces dynamically based on theme."
  (interactive)
  (let ((bg (face-background 'default))
        (fg (face-foreground 'default)))
    (set-face-attribute 'boba-calendar-selected nil
                        :foreground bg
                        :background fg
                        :inherit 'bold)
    (set-face-attribute 'boba-calendar-today nil
                        :inverse-video t
                        :inherit 'link :weight 'bold)))

(with-eval-after-load 'ui/theme
  (advice-add 'theme-refresh :after #'my-update-calendar-colors))

(my-update-calendar-colors)

(provide 'ui/calendar)
(provide 'boba-calendar)
;;; calendar.el ends here
