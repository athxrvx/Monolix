;;; agenda.el --- NΛNO agenda module -*- lexical-binding: t -*-

;; Copyright (C) 2021-2026 Free Software Foundation, Inc., Nicolas P. Rougier, Atomic Emacs

;; Maintainer: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; URL: https://github.com/rougier/boba-agenda
;; Version: 0.3
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, org-mode, org-agenda

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;;; Commentary:
;; Integrated NΛNO agenda module for Atomic Emacs. Displays a calendar view
;; of the current month alongside timestamped agenda entries in a single
;; buffer. Fully adapts to light/dark themes.

;;; Code:

(require 'org)
(require 'cl-lib)
(require 'org-agenda)
(require 'org-duration)
(require 'calendar)
(require 'holidays)
(require 'text-property-search)
(require 'ui/faces)
(require 'ui/theme)

(declare-function org-link-display-format "org")
(declare-function calendar-check-holidays "holidays")

(defgroup boba-agenda nil
  "NΛNO agenda settings"
  :group 'nano)

(defgroup boba-agenda-faces nil
  "NΛNO agenda faces"
  :group 'boba-agenda)

(defvar boba-agenda--current-selection (current-time)
  "Current selected date")

(defvar boba-agenda--entry-overlay nil
  "Current selected date")

(defvar boba-agenda--entry-select-mode nil
  "Flag for entry selection mode")

(defvar boba-agenda--busy-levels (list)
  "Cached list of (date busy-level) for internal use")

(defcustom boba-agenda-today-symbol  "•"
  "Symbol to show current day"
  :type 'string
  :group 'boba-agenda)

(defcustom boba-agenda-deadline-symbol "!"
  "Symbol to show a deadline in calendar"
  :type 'string
  :group 'boba-agenda)

(defcustom boba-agenda-separation "  "
  "Separation string between calendar and agenda entries"
  :type 'string
  :group 'boba-agenda)

(defcustom boba-agenda-sort-function #'boba-agenda-default-sort-function
  "Function to sort a day's entries.
This function takes an entries list and returns the list in the desired order."
  :type 'function
  :group 'boba-agenda)

(defcustom boba-agenda-filter-entry-predicate #'boba-agenda-filter-entry
  "Predicate to decide if entry will be shown in the boba-agenda buffer.
This function takes an entry and the selected date. Returns a value if the entry
should be shown, otherwise, returns nil."
  :type 'function
  :group 'boba-agenda)

;; See https://material.io/design/color/the-color-system.html
(defvar boba-agenda-palettes
  '((red         . ("#FFEBEE" "#FFCDD2" "#EF9A9A" "#E57373" "#EF5350"
                    "#F44336" "#E53935" "#D32F2F" "#C62828" "#B71C1C"))
    (pink        . ("#FCE4EC" "#F8BBD0" "#F48FB1" "#F06292" "#EC407A"
                    "#E91E63" "#D81B60" "#C2185B" "#AD1457" "#880E4F"))
    (purple      . ("#F3E5F5" "#E1BEE7" "#CE93D8" "#BA68C8" "#AB47BC"
                    "#9C27B0" "#8E24AA" "#7B1FA2" "#6A1B9A" "#4A148C"))
    (deep-purple . ("#EDE7F6" "#D1C4E9" "#B39DDB" "#9575CD" "#7E57C2"
                    "#673AB7" "#5E35B1" "#512DA8" "#4527A0" "#311B92"))
    (indigo      . ("#E8EAF6" "#C5CAE9" "#9FA8DA" "#7986CB" "#5C6BC0"
                    "#3F51B5" "#3949AB" "#303F9F" "#283593" "#1A237E"))
    (blue        . ("#E3F2FD" "#BBDEFB" "#90CAF9" "#64B5F6" "#42A5F5"
                    "#2196F3" "#1E88E5" "#1976D2" "#1565C0" "#0D47A1"))
    (light-blue  . ("#E1F5FE" "#B3E5FC" "#81D4FA" "#4FC3F7" "#29B6F6"
                    "#03A9F4" "#039BE5" "#0288D1" "#0277BD" "#01579B"))
    (cyan        . ("#E0F7FA" "#B2EBF2" "#80DEEA" "#4DD0E1" "#26C6DA"
                    "#00BCD4" "#00ACC1" "#0097A7" "#00838F" "#006064"))
    (teal        . ("#E0F2F1" "#B2DFDB" "#80CBC4" "#4DB6AC" "#26A69A"
                    "#009688" "#00897B" "#00796B" "#00695C" "#004D40"))
    (green       . ("#E8F5E9" "#C8E6C9" "#A5D6A7" "#81C784" "#66BB6A"
                    "#4CAF50" "#43A047" "#388E3C" "#2E7D32" "#1B5E20"))
    (light-green . ("#F1F8E9" "#DCEDC8" "#C5E1A5" "#AED581" "#9CCC65"
                    "#8BC34A" "#7CB342" "#689F38" "#558B2F" "#33691E"))
    (lime        . ("#F9FBE7" "#F0F4C3" "#E6EE9C" "#DCE775" "#D4E157"
                    "#CDDC39" "#C0CA33" "#AFB42B" "#9E9D24" "#827717"))
    (yellow      . ("#FFFDE7" "#FFF9C4" "#FFF59D" "#FFF176" "#FFEE58"
                    "#FFEB3B" "#FDD835" "#FBC02D" "#F9A825" "#F57F17"))
    (amber       . ("#FFF8E1" "#FFECB3" "#FFE082" "#FFD54F" "#FFCA28"
                    "#FFC107" "#FFB300" "#FFA000" "#FF8F00" "#FF6F00"))
    (orange      . ("#FFF3E0" "#FFE0B2" "#FFCC80" "#FFB74D" "#FFA726"
                    "#FF9800" "#FB8C00" "#F57C00" "#EF6C00" "#E65100"))
    (deep-orange . ("#FBE9E7" "#FFCCBC" "#FFAB91" "#FF8A65" "#FF7043"
                    "#FF5722" "#F4511E" "#E64A19" "#D84315" "#BF360C"))
    (brown       . ("#EFEBE9" "#D7CCC8" "#BCAAA4" "#A1887F" "#8D6E63"
                    "#795548" "#6D4C41" "#5D4037" "#4E342E" "#3E2723"))
    (grey        . ("#FAFAFA" "#F5F5F5" "#EEEEEE" "#E0E0E0" "#BDBDBD"
                    "#9E9E9E" "#757575" "#616161" "#424242" "#212121"))
    (blue-grey   . ("#ECEFF1" "#CFD8DC" "#B0BEC5" "#90A4AE" "#78909C"
                    "#607D8B" "#546E7A" "#455A64" "#37474F" "#263238"))))

(defun boba-agenda-color-luminance (color)
  "Calculate the relative luminance of a color string (e.g. \"#ffaa00\", \"blue\").
Return a value between 0 and 1."
  (let* ((values (color-values color))
         (red (/ (car values) 256.0))
         (green (/ (cadr values) 256.0))
         (blue (/ (caddr values) 256.0)))
    (/ (+ (* .2126 red) (* .7152 green) (* .0722 blue)) 255)))

(defcustom boba-agenda-palette 'amber
  "Background colors to use to highlight a day in calendar
view according to busy level."
  :type '(choice (const red)    (const pink)  (const purple)      (const deep-purple)
                 (const indigo) (const blue)  (const light-blue)  (const cyan)
                 (const teal)   (const green) (const light-green) (const lime)
                 (const yellow) (const amber) (const orange)      (const deep-orange)
                 (const brown)  (const grey)  (const blue-grey))
  :group 'boba-agenda-faces)

(defface boba-agenda-default nil
  "Default face (for casual day)"
  :group 'boba-agenda-faces)

(defface boba-agenda-selected nil
  "Face for the selected day"
  :group 'boba-agenda-faces)

(defface boba-agenda-time nil
  "Time face"
  :group 'boba-agenda-faces)

(defface boba-agenda-current-day nil
  "Current day face"
  :group 'boba-agenda-faces)

(defface boba-agenda-weekend nil
  "Weekend face"
  :group 'boba-agenda-faces)

(defface boba-agenda-holidays nil
  "Holidays face"
  :group 'boba-agenda-faces)

(defface boba-agenda-outday nil
  "Out day face, that is, day outside current month."
  :group 'boba-agenda-faces)

(defface boba-agenda-day-name nil
  "Day name face (on second line)"
  :group 'boba-agenda-faces)

(defface boba-agenda-month-name nil
  "Month name face (on first line)"
  :group 'boba-agenda-faces)

(defface boba-agenda-mouse nil
  "Mouse highlight face"
  :group 'boba-agenda-faces)

(defface boba-agenda-button nil
  "Header button (left and right)"
  :group 'boba-agenda-faces)

(defun boba-agenda-date (year month day)
  "Return a date corresponding to DAY/MONTH/YEAR."
  (encode-time 0 0 0 day month year))

(defun boba-agenda-date-equal (date1 date2)
  "Check if DATE1 is equal to DATE2."
  (and (eq (boba-agenda-date-day date1)
           (boba-agenda-date-day date2))
       (eq (boba-agenda-date-month date1)
           (boba-agenda-date-month date2))
       (eq (boba-agenda-date-year date1)
           (boba-agenda-date-year date2))))

(defun boba-agenda-date-inc (date &optional days months years)
  "Return DATE + DAYS day & MONTH months & YEARS years"
  (let ((days (or days 0))
        (months (or months 0))
        (years (or years 0))
        (day (boba-agenda-date-day date))
        (month (boba-agenda-date-month date))
        (year (boba-agenda-date-year date)))
    (encode-time 0 0 0 (+ day days) (+ month months) (+ year years))))

(defun boba-agenda-date-dec (date &optional days months years)
  "Return DATE - DAYS day & MONTH months & YEARS years"
  (let ((days (or days 0))
        (months (or months 0))
        (years (or years 0)))
    (boba-agenda-date-inc date (- days) (- months) (- years))))

(defvar boba-agenda-hook nil
  "Normal hook run after agenda is build")

(defvar boba-agenda-update-hook nil
  "Normal hook run after agenda is updated")

(defvar boba-agenda-entry-edit-hook nil
  "Normal hook run after the editing buffer is shown")

(defun boba-agenda-date-day (date)
  "Return DATE day of month (1-31)."
  (nth 3 (decode-time date)))
                        
(defun boba-agenda-date-month (date)
  "Return DATE month number (1-12)."
  (nth 4 (decode-time date)))

(defun boba-agenda-date-year (date)
  "Return DATE year."
  (nth 5 (decode-time date)))

(defun boba-agenda-date-doy (date)
  "Return DATE day of year (1-366)."
  (string-to-number (format-time-string "%j" date)))

(defun boba-agenda-date-dow (date)
  "Return DATE day of week (0-6)."
  (nth 6 (decode-time date)))

(defun boba-agenda-date-day-name (date)
  "Return DATE full day name."
  (format-time-string "%A" date))

(defun boba-agenda-date-month-name (date)
  "Return DATE full month name."
  (format-time-string "%B" date))

(defun boba-agenda-date-is-today (date)
  "Check if DATE is today."
  (boba-agenda-date-equal (current-time) date))

(defun boba-agenda-date-today ()
  "Return today date."
  (current-time))

(defun boba-agenda-date-tomorrow ()
  "Return tomorrow date."
  (boba-agenda-date-inc (boba-agenda-date-today) 1 0 0))
  
(defun boba-agenda-yesterday ()
  "Return yesterday date."
  (boba-agenda-date-dec (boba-agenda-date-today) 1 0 0))

(defun boba-agenda-forward-day ()
  "Move to next day in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection
          (boba-agenda-date-inc boba-agenda--current-selection 1))
    (boba-agenda-update)))

(defun boba-agenda-backward-day ()
  "Move to previous day in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection
          (boba-agenda-date-dec boba-agenda--current-selection 1))
    (boba-agenda-update)))

(defun boba-agenda-forward-week ()
  "Move to next week in calendar or next entry when entry-select-mode is active"
  (interactive)
  (if boba-agenda--entry-select-mode
      (boba-agenda-goto-next-entry)
    (progn (setq boba-agenda--current-selection
                 (boba-agenda-date-inc boba-agenda--current-selection 7))
           (boba-agenda-update))))

(defun boba-agenda-backward-week ()
  "Move to previous week in calendar or previous entry when entry-select-mode is active"
  (interactive)
  (if boba-agenda--entry-select-mode
      (boba-agenda-goto-prev-entry)
    (progn
      (setq boba-agenda--current-selection
            (boba-agenda-date-dec boba-agenda--current-selection 7))
      (boba-agenda-update))))

(defun boba-agenda-forward-month ()
  "Move to next month in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection
          (boba-agenda-date-inc boba-agenda--current-selection 0 1))
    (boba-agenda-update)))

(defun boba-agenda-backward-month ()
  "Move to previous month in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection
          (boba-agenda-date-dec boba-agenda--current-selection 0 1))
    (boba-agenda-update)))
  
(defun boba-agenda-forward-year ()
  "Move to next year in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection
          (boba-agenda-date-inc boba-agenda--current-selection 0 0 1))
    (boba-agenda-update)))
    
(defun boba-agenda-backward-year ()
  "Move to previous year in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection
          (boba-agenda-date-dec boba-agenda--current-selection 0 0 1))
    (boba-agenda-update)))

(defun boba-agenda-goto-today ()
  "Goto current day in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection (boba-agenda-date-today))
    (boba-agenda-update)))

(defun boba-agenda-goto (&optional date)
  "Goto given DATE (default today) in calendar"
  (interactive)
  (unless boba-agenda--entry-select-mode
    (setq boba-agenda--current-selection (or date (boba-agenda-date-today)))
    (boba-agenda-update)))

(define-minor-mode boba-agenda-mode
  "Minor mode for boba-agenda."
  :init nil
  :keymap `((,(kbd "<left>")    . boba-agenda-backward-day)
            (,(kbd "<right>")   . boba-agenda-forward-day)
            (,(kbd "<up>")      . boba-agenda-backward-week)
            (,(kbd "<down>")    . boba-agenda-forward-week)
            (,(kbd "<S-left>")  . boba-agenda-backward-month)
            (,(kbd "<S-right>") . boba-agenda-forward-month)
            (,(kbd "<S-up>")    . boba-agenda-backward-year)
            (,(kbd "<S-down>")  . boba-agenda-forward-year)
            (,(kbd "<tab>")     . boba-agenda-toggle-entry-select-mode)
            (,(kbd "<return>")  . org-agenda-goto)
            (,(kbd "r")         . boba-agenda-refresh)
            (,(kbd ".")         . boba-agenda-goto-today)
            (,(kbd "t")         . boba-agenda-goto-today)
            (,(kbd "C-g")       . boba-agenda-kill)
            (,(kbd "q")         . boba-agenda-kill)
            (,(kbd "<escape>")  . boba-agenda-kill))

  (when boba-agenda-mode
    (setq buffer-read-only t)
    (setq cursor-type nil)))

(defun boba-agenda--center-string (string size)
  (let* ((padding (/ (- size (length string)) 2))
         (lpad (+ (length string) padding))
         (lformat (format "%%%ds" lpad))
         (rformat (format "%%%ds" (- size))))
    (format rformat (format lformat string))))

(defun boba-agenda-select-window ()
  "Function to select where to show agenda. Default behavior is to split vertically."
  (let* ((agenda-buffer "*boba-agenda*")
         (agenda-window (get-buffer-window agenda-buffer)))
    (or agenda-window (split-window nil -10 'below))))

(defun boba-agenda-filter-entry (entry &optional _date)
  "Function to decide whether an entry is displayed/counted."
  (let ((type (get-text-property 0 'type entry)))
    (and (not (string-equal type "upcoming-deadline"))
         (not (string-search ":CANCELLED:" entry)))))

(defun boba-agenda-default-sort-function (entry-1 entry-2)
  "Function to decide the order ENTRIES will be shown to the user."
  (let ((time-1 (get-text-property 0 'time-of-day entry-1))
        (time-2 (get-text-property 0 'time-of-day entry-2)))
    (cond ((not time-1) t)
          ((not time-2) nil)
          (t (< time-1 time-2)))))

(defun boba-agenda-format-entry (entry)
  "Function to display a specific (org) entry"
  (let* ((is-deadline (string-equal (get-text-property 0 'type entry) "deadline"))
         (org-marker (get-text-property 0 'org-marker entry))
         (text (propertize (get-text-property 0 'txt entry)
                           'org-marker org-marker))
         (text (replace-regexp-in-string ":.*:" "" text))
         (text (org-link-display-format text))
         (text (string-trim text))
         (time-of-day (get-text-property 0 'time-of-day entry))
         (hours (when time-of-day (floor (/ time-of-day 100))))
         (text (if is-deadline
                   (propertize (concat "[D] " text) 'face 'org-imminent-deadline)
                 (propertize text 'face 'default))))
    (if hours
        (concat (propertize (format "%02dh" hours) 'face 'boba-agenda-time)
                " - "
                text)
      text)))

;;;###autoload
(defun boba-agenda ()
  "Create windows & buffers associated with the agenda."
  (interactive)
  (let* ((agenda-buffer "*boba-agenda*")
         (agenda-window (boba-agenda-select-window)))
    (setq boba-agenda--entry-overlay nil)
    (setq boba-agenda--entry-select-mode nil)
    (select-window agenda-window)
    (switch-to-buffer agenda-buffer)
    (let ((message-log-max nil)
          (inhibit-message t))
      (toggle-truncate-lines 1))
    (set-window-dedicated-p agenda-window t)
    (set-window-margins agenda-window 2 2)
    (boba-agenda-mode t)
    (boba-agenda-update)
    (show-paren-local-mode -1)
    (run-hooks 'boba-agenda-hook)))

(defun boba-agenda-update ()
  "Update calendar and agenda according to selected date."
  (when-let ((buf (get-buffer "*boba-agenda*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (goto-char (point-min))
        (boba-agenda--populate-calendar)
        (goto-char (point-min))
        (boba-agenda--populate-agenda)
        (when-let ((win (get-buffer-window buf)))
          (set-window-margins win 2 2)))
      (run-hooks 'boba-agenda-update-hook))))

(defun boba-agenda-kill ()
  "Kill buffers and windows associated with the agenda."
  (interactive)
  (let* ((calendar-buffer "*boba-calendar*")
         (agenda-buffer "*boba-agenda*"))
    (if (get-buffer calendar-buffer)
        (kill-buffer calendar-buffer))
    (if (get-buffer agenda-buffer)
        (kill-buffer agenda-buffer))))

(defun boba-agenda-refresh ()
  "Reset the cache of busy levels."
  (interactive)
  (setq boba-agenda--busy-levels (list))
  (boba-agenda-update))

(defun boba-agenda--has-deadline (date)
  "Check if a cached entry has a deadline"
  (let* ((day   (boba-agenda-date-day   date))
         (month (boba-agenda-date-month date))
         (year  (boba-agenda-date-year  date))
         (date  (list month day year))
         (entry (assoc date boba-agenda--busy-levels)))
    (when entry
      (nth 2 entry))))

(defun boba-agenda--busy-level (date)
  "Compute the busy level at a given date. Computed levels are cached."
  (let* ((day   (boba-agenda-date-day   date))
         (month (boba-agenda-date-month date))
         (year  (boba-agenda-date-year  date))
         (date  (list month day year))
         (level 0)
         (deadline nil)
         (entry (assoc date boba-agenda--busy-levels)))
    (if entry
        (cadr entry)
      (progn
        (dolist (file (org-agenda-files))
          (dolist (entry (org-agenda-get-day-entries file date))
            (when (string-equal (get-text-property 0 'type entry) "deadline")
              (setq deadline t))
            (when (funcall boba-agenda-filter-entry-predicate entry date)
              (setq level (+ level 1)))))
        (add-to-list 'boba-agenda--busy-levels `(,date ,level ,deadline))
        level))))

(defun boba-agenda--populate-agenda ()
  "Populate the agenda according to current selected date."
  (let* ((selected boba-agenda--current-selection)
         (day      (boba-agenda-date-day   selected))
         (month    (boba-agenda-date-month selected))
         (year     (boba-agenda-date-year  selected))
         (date     (list month day year))
         (is-today (boba-agenda-date-is-today selected))
         (holidays (calendar-check-holidays date))
         (entries '()))

    ;; Header (literal date + holidays (if any))
    (forward-line)
    (end-of-line)
    (insert boba-agenda-separation)
    (insert (propertize (format-time-string "%A %-e %B %Y" selected)
                        'face 'boba-agenda-current-day))
    (end-of-line)

    (if is-today
        (insert (propertize (format-time-string " (%H:%M)")
                            'face 'boba-agenda-time))
      (when holidays
        (insert (propertize (format " %s" holidays)
                            'face 'boba-agenda-holidays))))
    (forward-line 2)
    (end-of-line)

    ;; Body (default timed entries)
    (dolist (file (org-agenda-files))
      (dolist (entry (org-agenda-get-day-entries file date))
        (when (funcall boba-agenda-filter-entry-predicate entry date)
          (cl-pushnew entry entries :test #'equal))))

    ;; Sort entries
    (setq entries (sort entries boba-agenda-sort-function))

    ;; Display entries
    (let ((limit (if (< (length entries) 7) 7 5)))
      (dolist (entry (cl-subseq entries 0 (min limit (length entries))))
        (insert boba-agenda-separation)
        (let* ((org-marker (get-text-property 0 'org-marker entry))
               (entry-text (boba-agenda-format-entry entry))
               (entry-beg (- (point) 1))
               (entry-end (+ (point) (length entry-text) 1)))
          (insert (propertize (concat entry-text " ")
                              'overlay (cons entry-beg entry-end)))
          (add-text-properties (line-beginning-position) (line-end-position)
                               `(org-marker ,org-marker)))
        (forward-line)
        (end-of-line))
      (if (> (length entries) limit)
          (insert (concat boba-agenda-separation
                          (format "+%S non-displayed event(s)" (- (length entries) limit))))))
    (goto-char (point-min))))

(defun boba-agenda-select-entry ()
  (interactive)
  (let* ((match (text-property-search-forward 'overlay nil nil t)))
    (when match
      (let* ((bounds (prop-match-value match))
             (overlay (or boba-agenda--entry-overlay
                          (make-overlay (car bounds) (cdr bounds)))))
        (setq boba-agenda--entry-overlay overlay)
        (move-overlay overlay (car bounds) (cdr bounds))
        (overlay-put overlay 'face 'boba-agenda-selected)))))

(defun boba-agenda-toggle-entry-select-mode ()
  "Toggle entry select mode"
  (interactive)
  (if boba-agenda--entry-select-mode
      (progn
        (setq boba-agenda--entry-select-mode nil)
        (boba-agenda-update)
        (when boba-agenda--entry-overlay
          (overlay-put boba-agenda--entry-overlay 'face 'default)))
    (progn
      (setq boba-agenda--entry-select-mode t)
      (boba-agenda-update)
      (boba-agenda-goto-next-entry))))

(defun boba-agenda-goto-next-entry ()
  "Select next entry (when in entry select mode)"
  (interactive)
  (when boba-agenda--entry-select-mode
    (when-let* ((match (text-property-search-forward 'overlay nil nil t))
                (bounds (prop-match-value match))
                (overlay (or boba-agenda--entry-overlay
                             (make-overlay (car bounds) (cdr bounds)))))
      (setq boba-agenda--entry-overlay overlay)
      (move-overlay overlay (car bounds) (cdr bounds))
      (overlay-put overlay 'face 'boba-agenda-selected))))

(defun boba-agenda-goto-prev-entry ()
  "Select prev entry (when in entry select mode)"
  (interactive)
  (when boba-agenda--entry-select-mode
    (when-let* ((match (text-property-search-backward 'overlay nil nil t))
                (bounds (prop-match-value match))
                (overlay (or boba-agenda--entry-overlay
                             (make-overlay (car bounds) (cdr bounds)))))
      (setq boba-agenda--entry-overlay overlay)
      (move-overlay overlay (car bounds) (cdr bounds))
      (overlay-put overlay 'face 'boba-agenda-selected))))

(defun boba-agenda--populate-calendar ()
  "Populate the calendar according to the month of the current selected date."
  (let* ((selected boba-agenda--current-selection)
         (map-left (make-sparse-keymap))
         (map-right (make-sparse-keymap)))

    (define-key map-left (kbd "<down-mouse-1>") #'boba-agenda-backward-month)
    (define-key map-right (kbd "<down-mouse-1>") #'boba-agenda-forward-month)

    (insert "\n")
    (insert (propertize "<" 'face 'boba-agenda-button
                        'mouse-face 'boba-agenda-mouse
                        'help-echo "Previous month"
                        'keymap map-left))
    (insert (propertize (boba-agenda--center-string
                         (format "%s %d"
                                 (boba-agenda-date-month-name selected)
                                 (boba-agenda-date-year selected)) 18)
                        'face 'boba-agenda-month-name))
    (insert (propertize "> " 'face 'boba-agenda-button
                        'mouse-face 'boba-agenda-mouse
                        'help-echo "Next month"
                        'keymap map-right))
    (insert "\n")
    (insert (propertize "Mo Tu We Th Fr "
                        'face 'boba-agenda-day-name))
    (insert (propertize "Sa Su "
                        'face 'boba-agenda-day-name))
    (insert "\n"))
  
  (let* ((selected boba-agenda--current-selection)
         (month    (boba-agenda-date-month selected))
         (year     (boba-agenda-date-year selected))
         (start    (boba-agenda-date year month 1))
         (dow      (mod (+ 6 (boba-agenda-date-dow start)) 7))
         (start    (boba-agenda-date-dec start dow)))

    (dotimes (row 6)
      (dotimes (col 7)
        (let* ((day (+ (* row 7) col))
               (date (boba-agenda-date-inc start day))
               (level (boba-agenda--busy-level date))
               (backgrounds (alist-get boba-agenda-palette boba-agenda-palettes))
               ;; Reverse backgrounds list in dark theme to map subtle highlights properly
               (backgrounds (if (eq (frame-parameter nil 'background-mode) 'dark)
                                (reverse backgrounds)
                              backgrounds))
               (level (min (length backgrounds) level))
               (background (nth (- level 1) backgrounds))
               (foreground (if (< (boba-agenda-color-luminance background) 0.5)
                               "white" "black"))
               (map (make-sparse-keymap))
               (is-today (boba-agenda-date-is-today date))
               (has-deadline (boba-agenda--has-deadline date))
               (is-selected (boba-agenda-date-equal date selected))
               (is-outday (not (= (boba-agenda-date-month date) month)))
               (is-holidays (calendar-check-holidays (list
                                                      (boba-agenda-date-month date)
                                                      (boba-agenda-date-day date)
                                                      (boba-agenda-date-year date))))
               (is-weekend (or (= (boba-agenda-date-dow date) 0)
                               (= (boba-agenda-date-dow date) 6)))
               (face (cond ((and is-selected (not boba-agenda--entry-select-mode))
                            'boba-agenda-selected)
                           (is-outday         'boba-agenda-outday)
                           ((> level 0)       `(:foreground ,foreground :background ,background ))
                           (is-weekend        'boba-agenda-weekend)
                           (is-holidays       'boba-agenda-holidays)
                           (t                 'boba-agenda-default))))

          (define-key map (kbd "<down-mouse-1>")
            `(lambda() (interactive) (boba-agenda-goto ,date)))

          (insert (propertize (format "%2d" (boba-agenda-date-day date))
                              'face face
                              'mouse-face (cond (is-selected 'boba-agenda-selected)
                                                (t           'boba-agenda-mouse))
                              'help-echo (format "%s%s" (format-time-string "%A %-e %B %Y" date)
                                                 (if is-holidays (format " (%s)" (nth 0 is-holidays))
                                                   ""))
                              'keymap map))
          (if (< col 7)
              (insert (propertize (cond (is-today boba-agenda-today-symbol)
                                        (has-deadline boba-agenda-deadline-symbol)
                                        (t " "))
                                  'face face)))))
      (if (< row 5) (insert "\n")))))

;; =========================================================================
;; Dynamic Theme Support
;; =========================================================================

(defun my-update-agenda-colors ()
  "Update custom boba-agenda faces dynamically based on theme."
  (interactive)
  (set-face-attribute 'boba-agenda-default nil
                      :inherit 'default)
  (set-face-attribute 'boba-agenda-selected nil
                      :foreground (face-background 'default nil t)
                      :background (face-foreground 'default nil t)
                      :inherit 'bold)
  (set-face-attribute 'boba-agenda-time nil
                      :inherit 'theme-face-faded)
  (set-face-attribute 'boba-agenda-current-day nil
                      :inherit 'theme-face-strong)
  (set-face-attribute 'boba-agenda-weekend nil
                      :inherit 'theme-face-faded)
  (set-face-attribute 'boba-agenda-holidays nil
                      :inherit 'theme-face-faded)
  (set-face-attribute 'boba-agenda-outday nil
                      :inherit 'theme-face-subtle)
  (set-face-attribute 'boba-agenda-day-name nil
                      :inherit 'theme-face-faded)
  (set-face-attribute 'boba-agenda-month-name nil
                      :inherit 'theme-face-strong)
  (set-face-attribute 'boba-agenda-mouse nil
                      :inherit 'highlight)
  (set-face-attribute 'boba-agenda-button nil
                      :inherit 'theme-face-faded))

(with-eval-after-load 'ui/theme
  (advice-add 'theme-refresh :after #'my-update-agenda-colors))

(my-update-agenda-colors)

(provide 'ui/agenda)
(provide 'boba-agenda)
;;; agenda.el ends here
