;;; scratch.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Variables

(defcustom lem-persistent-scratch t
  "If t, make scratch buffer persist across sessions.
Default is to persist."
  :group 'lambda-emacs
  :type 'boolean)

(defcustom lem-scratch-save-dir lem-cache-dir
  "Default directory for saving scratch file."
  :group 'lambda-emacs
  :type 'string)

(defcustom lem-scratch-default-dir (concat (getenv "HOME") "/")
  "Default directory for scratch buffer.
User may prefer to set this to `lem-scratch-save-dir'."
  :group 'lambda-emacs
  :type 'string)

;;;; Functions

(defun lem--bury-scratch ()
  "Don't kill scratch buffer, bury it."
  (if (eq (current-buffer) (get-buffer "*scratch*"))
      (progn (bury-buffer)
             nil)
    t))

(add-hook 'kill-buffer-query-functions 'lem--bury-scratch)

(defun lem--save-persistent-scratch ()
  "Save the contents of *scratch*."
  (with-current-buffer (get-buffer-create "*scratch*")
    (write-region (point-min) (point-max)
                  (concat lem-scratch-save-dir "scratch"))))

(defun lem--load-persistent-scratch ()
  "Reload the scratch buffer."
  (let ((scratch-file (concat lem-scratch-save-dir "scratch")))
    (if (file-exists-p scratch-file)
        (with-current-buffer (get-buffer "*scratch*")
          (delete-region (point-min) (point-max))
          (insert-file-contents scratch-file))))
  ;; set default dir for scratch buffer
  (with-current-buffer (get-buffer "*scratch*")
    (setq-local default-directory lem-scratch-default-dir)))

;; Hooks for loading and saving the scratch buffer
(cond (lem-persistent-scratch
       (add-hook 'after-init-hook 'lem--load-persistent-scratch)
       (add-hook 'kill-emacs-hook 'lem--save-persistent-scratch)
       ;; Save scratch buffer every 5 minutes (300 seconds)
       (run-with-idle-timer 300 t 'lem--save-persistent-scratch)))

;;; End Setup-Scratch
(provide 'component/scratch)
;;; lem-setup-scratch.el ends here
