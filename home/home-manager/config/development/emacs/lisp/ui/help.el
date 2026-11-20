;;; help.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(defun boba-quick-help ()
  (interactive)
  (let ((message-log-max nil))
    (message
     (concat
      (propertize "\n" 'face '(:height 0.4))
      " [C-x C-f] Open  [M-w] Copy   [C-w] Cut   [C-s] Search           "
      (propertize "[C-g]   Cancel" 'face 'bold)
      "\n"
      " [C-x C-s] Save  [C-y] Paste  [C-/] Undo  [M-x] Command          "
      (propertize "[C-x C-c] Quit" 'face 'bold)
      (propertize "\n " 'face '(:height 0.5))))
    (sit-for 30)))

;; Help screen
(define-derived-mode help-mode org-mode "Nano help mode")
(define-key help-mode-map (kbd "q") #'kill-current-buffer)
(defun boba-help ()
  (interactive)
  (find-file-read-only (locate-file "quick-help.org" load-path))
  (help-mode)
  (setq-local org-confirm-elisp-link-function nil))

;; Bindings for quick help and help
(setq mac-pass-command-to-system nil)
(global-set-key (kbd "M-p") 'boba-quick-help)
(global-set-key (kbd "M-h") 'boba-help)

(defun dashboard-splash-help-message ()
  (message
   (concat
    (if (display-graphic-p) (propertize "\n " 'face '(:height 0.4)))
    (propertize (concat
                 "Type M-p for quick help, M-h for help."
                 " M stands for Alt, Command or (Esc)ape.")
                'face 'theme-face-faded)
    (if (display-graphic-p) (propertize "\n " 'face '(:height 0.5))))))

(provide 'ui/help)
