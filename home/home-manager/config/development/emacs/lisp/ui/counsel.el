;;; counsel.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(require 'smex)

(setq ivy-height 4)
(setq ivy-count-format "")
(setq ivy-initial-inputs-alist: '((counsel-minor .            "^+")
                                  (counsel-package .          "^+")
                                  (counsel-org-capture .      "^")
                                  (counsel-M-x .              "^")
                                  (counsel-describe-symbol .  "^")
                                  (org-refile .               "") 
                                  (org-agenda-refile .        "")
                                  (org-capture-refile .       "")
                                  (Man-completion-table .     "^")
                                  (woman .                    "^")))
(global-set-key (kbd "M-x")     'counsel-M-x)


(global-set-key (kbd "C-c r")   'counsel-recentf)
(global-set-key (kbd "C-c b")   'counsel-bookmark)
(global-set-key (kbd "C-x C-b") 'counsel-switch-buffer)
(global-set-key (kbd "C-c c")   'counsel-org-capture)
(ivy-mode 1)
(setq ivy-use-virtual-buffers t)
(setq enable-recursive-minibuffers t)


(provide 'counsel)
