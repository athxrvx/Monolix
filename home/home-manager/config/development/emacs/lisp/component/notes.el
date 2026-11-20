;;; notes.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Notebook Setup

(defcustom lem-notes-dir nil
  "Set a directory path for notes."
  :group 'lambda-emacs
  :type 'string)

;;;; Denote
;; Simple and deliberate note-taking with Denote
;; https://github.com/protesilaos/denote
;; See also https://systemcrafters.net/live-streams/july-15-2022/

(use-package denote
  :when (and lem-load-extras (locate-library "denote"))
  :commands (denote denote-create-note denote-link-ol-store)
  :custom
  ;; Use org-read-date
  (denote-date-prompt-use-org-read-date t)
  (denote-file-type 'org) ;; use org
  (denote-allow-multi-word-keywords nil) ;; single word keywords only
  ;; Better backlink display
  (denote-link-backlinks-display-buffer-action
   (quote ((display-buffer-reuse-window
            display-buffer-in-side-window)
           (inhibit-same-window . t)
           (side . bottom)
           (slot . 99)
           (window-height . 10))))
  ;; Set default prompts for note creation
  (denote-prompts '(title keywords subdirectory))
  ;; Set multiple keywords as a list of strings
  (denote-known-keywords '("workbook" "project" "idea")))

;; Org-capture note creation with Denote
(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("n" "New note (with Denote)" plain
                 (file denote-last-path)
                 #'denote-org-capture
                 :no-save t
                 :immediate-finish nil
                 :kill-buffer t
                 :jump-to-captured t)))

(defun lem-denote-capture-note ()
  "Create a new note with denote."
  (interactive)
  (org-capture nil "n"))

;; Example note creation function
(defun lem-insert-header-and-time-property ()
  "Insert an org heading with a created time string property."
  (interactive)
  (insert "* ")
  (org-set-property "CREATED" (format-time-string "[%Y-%m-%d %T]")))

(defun lem-denote-workbook-create-entry ()
  "Create an entry tagged 'workbook' with the date as its title."
  (interactive)
  (denote
   (format-time-string "%Y %A %e %B")   ; format like Tuesday 14 June 2022
   '("workbook")
   nil
   (concat denote-directory "workbook")
   nil
   nil)
  (lem-insert-header-and-time-property))



;;;; Citar-Denote
;; Integration of denote with citar
(use-package citar-denote
  :when (and lem-load-extras (locate-library "citar-denote"))
  :commands (citar-create-note
             citar-open-notes
             citar-denote-add-citekey)
  :config
  (citar-denote-mode))

;;;; Consult Notes
;; Adapted from https://github.com/minad/consult/wiki/hrm-notes
(use-package consult-notes
  :when (and lem-load-extras (locate-library "consult-notes"))
  :commands (consult-notes
             consult-notes-search-in-all-notes))

(defun lem-notebook ()
  "Open `consult-notes in buffer window rather than minibuffer."
  (interactive)
  (let ((vertico-buffer-display-action
         '(display-buffer-reuse-window)))
    (consult-notes)))


;;; Provide Setup-Notes
(provide 'component/notes)
;;; lem-setup-notes.el ends here
