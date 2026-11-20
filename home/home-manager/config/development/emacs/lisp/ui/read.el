;;; read.el --- NANO read                       -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Nicolas P. Rougier (inria)

;; Author: Nicolas P. Rougier (inria) <nicolas.rougier@inria.fr>
;; URL: https://github.com/rougier/boba-read
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: minibuffer convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; boba-read functions allows the user to enter text in the minibuffer
;; while some information is displayed on the right side (right
;; margin).
;;

;;; Code:

(defface boba-read-face
  `((t :inherit widget-field))
  "Face for entry")

(defface boba-read-prompt-default-face nil
  "Face for default prompt")

(defface boba-read-prompt-warning-face nil
  "Face for warning prompt")

(defvar boba-read-prompt-face 'boba-read-prompt-default-face
  "Prompt face")

(defvar boba-read-with-date-map
  (define-keymap
      :parent minibuffer-mode-map
    "<tab>"       #'boba-read-with-date--today
    "S-<right>"   #'boba-read-with-date--forward-day
    "S-<left>"    #'boba-read-with-date--backward-day
    "M-<right>"   #'boba-read-with-date--forward-week
    "M-<left>"    #'boba-read-with-date--backward-week
    "M-S-<right>" #'boba-read-with-date--forward-month
    "M-S-<left>"  #'boba-read-with-date--backward-month
    "S-<down>"    #'boba-read-with-date--backward-30mn
    "S-<up>"      #'boba-read-with-date--forward-30mn)
  "Keymap used in conjunction with the `boba-read-with-date'.")

(defvar boba-read-with-list-map
  (define-keymap
      :parent minibuffer-mode-map
    "<tab>"    #'boba-read-with-list--next
    "S-<down>" #'boba-read-with-list--next
    "S-<up>"   #'boba-read-with-list--prev)
  "Keymap used in conjunction with the `boba-read-with-list'.")

(defvar boba-read-with-result-map
  (define-keymap
      :parent minibuffer-mode-map
    "<tab>"  #'boba-read-with-result--eval)
  "Keymap used in conjunction with the `boba-read-with-result'.")

(defvar boba-read-yes-or-no-map
  (define-keymap
      :parent minibuffer-mode-map
      "<tab>"   #'boba-read-with-list--next
      "<down>"  #'boba-read-with-list--next
      "<up>"    #'boba-read-with-list--prev
      "<right>" #'boba-read-with-list--next
      "<left>"  #'boba-read-with-list--prev
      "y"       #'boba-read-yes-or-no--yes
      "n"       #'boba-read-yes-or-no--no)
  "Keymap used in conjunction with the `boba-read-yes-or-no'.")

(defun boba-read--format-date (date)
  "Format DATE for minibuffer right margin."
  (concat (propertize (format-time-string "%a %d %b %Y, " date)
                       'face `(:weight ,(face-attribute 'default :weight)))
          (propertize (format-time-string "%H:%M" date)
                       'face `(:weight ,(face-attribute 'bold :weight)))))

(defun boba-read--format-list (list)
  "Format LIST for minibuffer right margin."
  (nth (car list) (cdr list)))

(defun boba-read--format-info (info)
  "Format INFO for minibuffer right margin."
  info)

(defvar boba-read--eval nil)
(defvar boba-read--result nil)
(defvar boba-read--info nil)
(defvar boba-read-prompt-in-margin nil)

(defun boba-read-with-result--eval ()
  "Evaluate current minibuffer content"
  (interactive)
  (let ((content (buffer-substring-no-properties (length (minibuffer-prompt))
                                                 (point-max))))
    (when (functionp boba-read--eval)
      (condition-case nil
          (let ((result (funcall boba-read--eval content)))
            (setq boba-read--result (if (stringp result) result "..."))
            (setcdr boba-read--info (if (stringp result) result "..."))
            )
        (setcdr boba-read--info "Error")))
    (boba-read--update)))

(defun boba-read-with-list--next ()
  "Select next item in current list"
  (interactive)
  (let* ((list (cdr boba-read--info))
         (index (car list))
         (items (cdr list))
         (index (mod (1+ index) (length items))))
    (setcdr boba-read--info (cons index items)))
  (boba-read--update))

(defun boba-read-with-list--prev ()
  "Select previous item in current list"
  (interactive)
  (let* ((list (cdr boba-read--info))
         (index (car list))
         (items (cdr list))
         (index (mod (1- index) (length items))))
    (setcdr boba-read--info (cons index items)))
  (boba-read--update))

(defun boba-read-yes-or-no--yes ()
  "Select YES answer (if present in the current list)"
  (interactive)
  (let ((list (cdr boba-read--info)))
    (when (or (member "YES" (cdr list))
              (member "Yes" (cdr list))
              (member "yes" (cdr list)))
      (setcdr boba-read--info (cons 0 '("YES"))))
    (exit-minibuffer)))

(defun boba-read-yes-or-no--no ()
  "Select NO answer (if present in the current list)"
  (interactive)
  (let ((list (cdr boba-read--info)))
    (when (or (member "NO" (cdr list))
              (member "No" (cdr list))
              (member "no" (cdr list)))
      (setcdr boba-read--info (cons 0 '("NO"))))
    (exit-minibuffer)))

(defun boba-read-with-date--set-date (minutes hours days months years)
  "Add MINUTES minutes, HOURS hours, DAYS day, MONTH months & YEARS
years to DATE and display it."
  (let* ((date (cdr boba-read--info))
         (date (decode-time date))
         (date (encode-time 0
                            (+ minutes (nth 1 date))
                            (+ hours (nth 2 date))
                            (+ days (nth 3 date))
                            (+ months (nth 4 date))
                            (+ years (nth 5 date)))))
    (setcdr boba-read--info date)
    (boba-read--update)))

(defun boba-read-with-date--today ()
  (interactive)
  (let* ((date (decode-time (current-time))))
    (setf (nth 1 date) 0)
    (setcdr boba-read--info (encode-time date))
    (boba-read--update)))

(defun boba-read-with-date--forward-30mn ()
  (interactive)
  (boba-read-with-date--set-date +30 0 0 0 0))

(defun boba-read-with-date--backward-30mn ()
  (interactive)
  (boba-read-with-date--set-date  -30 0 0 0 0))

(defun boba-read-with-date--forward-hour ()
  (interactive)
  (boba-read-with-date--set-date 0 +1 0 0 0))

(defun boba-read-with-date--backward-hour ()
  (interactive)
  (boba-read-with-date--set-date  0 -1 0 0 0))

(defun boba-read-with-date--forward-day ()
  (interactive)
  (boba-read-with-date--set-date 0 0 +1 0 0))

(defun boba-read-with-date--backward-day ()
  (interactive)
  (boba-read-with-date--set-date 0 0 -1 0 0))

(defun boba-read-with-date--forward-week ()
  (interactive)
  (boba-read-with-date--set-date 0 0 +7 0 0))

(defun boba-read-with-date--backward-week ()
  (interactive)
  (boba-read-with-date--set-date 0 0 -7 0 0))

(defun boba-read-with-date--forward-month ()
  (interactive)
  (boba-read-with-date--set-date 0 0 0 +1 0))

(defun boba-read-with-date--backward-month ()
  (interactive)
  (boba-read-with-date--set-date 0 0 0 -1 0))

(defun boba-read-with-date--forward-year ()
  (interactive)
  (boba-read-with-date--set-date 0 0 0 0 +1))

(defun boba-read-with-date--backward-year ()
  (interactive)
  (boba-read-with-date--set-date 0 0 0 0 -1))

(defun boba-read--update ()
  "Update minibuffer right margin according to current mode;"
  (let* ((inhibit-read-only t)
         (formatter (car boba-read--info))
         (info      (cdr boba-read--info))
         (info      (funcall formatter info))
         (info      (if (stringp info) info ""))
         (prompt (substring (minibuffer-prompt) 2 (length (minibuffer-prompt)))))
    (add-text-properties (+ 0 (point-min)) (+ 1 (point-min))
                         `(display ((margin right-margin) ,info)))
    (if boba-read-prompt-in-margin
        (progn
          (set-window-margins nil (+ 1 (length prompt)) (+ 1 (length info)))
          (add-text-properties (+ 1 (point-min)) (+ 3 (length prompt))
                               `(display ((margin left-margin) ,prompt))))
      (progn
          (set-window-margins nil 0 (+ 1 (length info)))
          (add-text-properties (+ 1 (point-min)) (+ 2 (point-min))
                               `(display ((margin left-margin) " ")))))))

(defun boba-read--setup (&optional prompt-in-margin)
  "Setup minibuffer for boba-read"
  (setq truncate-lines -1)
  (visual-line-mode 1)
  (setq-local boba-read-prompt-in-margin prompt-in-margin)
  (make-local-variable 'face-remapping-alist)
  (add-to-list 'face-remapping-alist `(default boba-read-face))
  (boba-read--update))

(defun boba-read--stylize-prompt (prompt)
  "Stylize a prompt to add box around it"
  (propertize (concat (propertize " " 'display '(raise +0.15))
                      prompt
                      (propertize " " 'display '(raise -0.15)))
              'face boba-read-prompt-face))

(defun boba-read (prompt &optional default prompt-in-margin)
  "Read a string from the minibuffer, prompting with string PROMPT."
  (setq boba-read--info (cons #'identity ""))
  (minibuffer-with-setup-hook
      (:append (lambda () (boba-read--setup prompt-in-margin)))
    (let ((enable-recursive-minibuffers nil))
      (read-from-minibuffer (concat "  "
                                    (boba-read--stylize-prompt prompt)
                                    " ") default))))

(defun boba-read-with-result (prompt eval-fun &optional default prompt-in-margin)
  "Read a string from the minibuffer, prompting with string PROMPT while
displaying evaluation of the content using EVAL-FUN."
  (setq boba-read--info (cons #'boba-read--format-info
                              ""))
  (setq boba-read--eval eval-fun)
  (minibuffer-with-setup-hook
      (:append (lambda () (boba-read--setup prompt-in-margin)))
    (let ((enable-recursive-minibuffers nil))
      (add-hook 'post-command-hook #'boba-read-with-result--eval)
      (unwind-protect
          (read-from-minibuffer (concat "  "
                                        (boba-read--stylize-prompt prompt)
                                        " ") default boba-read-with-result-map)
        (remove-hook 'post-command-hook #'boba-read-with-result--eval))))
  (kill-new boba-read--result)
  boba-read--result)

(defun boba-read-with-info (prompt info &optional default prompt-in-margin)
  "Read a string from the minibuffer, prompting with string PROMPT while displaying INFO."
  (setq boba-read--info (cons #'boba-read--format-info
                              info))
  (minibuffer-with-setup-hook
      (:append (lambda () (boba-read--setup prompt-in-margin)))
    (let ((enable-recursive-minibuffers nil))
      (read-from-minibuffer (concat "  "
                                    (boba-read--stylize-prompt prompt)
                                    " ") default))))

(defun boba-read-with-date (prompt &optional date default prompt-in-margin)
  "Read a string and a date from the minibuffer, prompting with string PROMPT."
  (let* ((date (decode-time (or date (current-time)))))
    (setf (nth 1 date) 0)
    (setq boba-read--info (cons #'boba-read--format-date
                                (encode-time date))))
  (minibuffer-with-setup-hook
      (:append (lambda () (boba-read--setup prompt-in-margin)))
    (let ((enable-recursive-minibuffers nil))
      (cons (read-from-minibuffer (concat "  "
                                          (boba-read--stylize-prompt prompt)
                                          " ")
                                  default boba-read-with-date-map)
            (cdr boba-read--info)))))

(defun boba-read-with-list (prompt list &optional default prompt-in-margin)
  "Read a string and a choice in LIST from the minibuffer, prompting with string PROMPT."
  (setq boba-read--info (cons #'boba-read--format-list
                              (cons 0 list)))
  (minibuffer-with-setup-hook
      (:append (lambda () (boba-read--setup prompt-in-margin)))
    (let ((enable-recursive-minibuffers nil))
      (cons (read-from-minibuffer (concat "  "
                                          (boba-read--stylize-prompt prompt)
                                          " ")
                                  default boba-read-with-list-map)
            (let ((list (cdr boba-read--info)))
              (nth (car list) (cdr list)))))))

(defun boba-read-yes-or-no (prompt &optional default list prompt-in-margin)
  "Read a YES/NO answer from the minibuffer"
  (setq boba-read--info (cons #'boba-read--format-list
                              (cons 0 (or list (list "YES" "NO")))))
  (minibuffer-with-setup-hook
      (:append (lambda ()
                 (boba-read--setup prompt-in-margin)
                 (goto-char (point-min))
                 (setq cursor-type nil)))
    (define-key boba-read-yes-or-no-map [t] 'ignore)
    (define-key boba-read-yes-or-no-map (kbd "<return>") #'exit-minibuffer)
    (let ((history-add-new-input nil)
          (boba-read-prompt-face 'boba-read-prompt-warning-face)
          (enable-recursive-minibuffers nil))
      (read-from-minibuffer (concat "  "
                                    (boba-read--stylize-prompt prompt)
                                    " ")
                            default boba-read-yes-or-no-map))
    (let ((list (cdr boba-read--info)))
      (nth (car list) (cdr list)))))

(defun my-update-read-colors ()
  "Update custom boba-read faces dynamically based on theme."
  (interactive)
  (let ((bg (face-background 'default))
        (link-fg (face-foreground 'link nil t))
        (err-fg (face-foreground 'error nil t)))
    (set-face-attribute 'boba-read-prompt-default-face nil
                        :foreground bg
                        :background link-fg
                        :weight (face-attribute 'bold :weight nil 'default)
                        :box bg)
    (set-face-attribute 'boba-read-prompt-warning-face nil
                        :foreground bg
                        :background err-fg
                        :weight (face-attribute 'bold :weight nil 'default)
                        :box err-fg)))

(with-eval-after-load 'ui/theme
  (advice-add 'theme-refresh :after #'my-update-read-colors))

(my-update-read-colors)

(provide 'ui/read)
(provide 'boba-read)
;;; read.el ends here
