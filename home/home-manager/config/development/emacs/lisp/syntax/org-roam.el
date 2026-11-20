;;; org-roam.el --- Org Roam configuration -*- lexical-binding: t; -*-

(require 'org)

;; Set up Org-roam package
(use-package org-roam
  :straight t
  :init
  (require 'ui/session)
  (unless (file-exists-p (expand-file-name "org-roam" boba-data-dir))
    (make-directory (expand-file-name "org-roam" boba-data-dir) t))
  :custom
  (org-roam-directory (expand-file-name "org-roam" boba-data-dir))
  (org-roam-database-connector 'sqlite-builtin)
  (org-roam-dailies-directory "daily/")
  (org-roam-graph-viewer #'view-file)
  :config
  ;; Custom Capture Templates
  (setq org-roam-capture-templates
        '(("d" "Default Note" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+created: %U\n#+filetags: \n\n* Introduction\n\n%?")
           :unnarrowed t)))

  ;; Custom Dailies Templates
  (setq org-roam-dailies-capture-templates
        '(("d" "Default Daily Entry" entry "* %?"
           :target (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d %A>\n#+filetags: :daily:\n\n* Daily Journal\n"))))

  ;; Start db autosync
  (org-roam-db-autosync-mode 1))

;; Consult-org-roam for Vertico integration
(use-package consult-org-roam
  :straight t
  :after (org-roam consult)
  :config
  (consult-org-roam-mode 1)
  (setq consult-org-roam-grep-func #'consult-ripgrep)
  (setq consult-org-roam-buffer-narrow-key ?r))

;; Web Graph view
(use-package org-roam-ui
  :straight (:host github :repo "org-roam/org-roam-ui" :branch "main" :files ("*" "out" "dist"))
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(defun boba-roam-text-graph-insert (node-id visited-ref level prefix connector next-prefix)
  "Recursively insert NODE-ID and its children into the buffer.
VISITED-REF is a cons cell containing the list of visited node IDs."
  (when (and node-id (not (member node-id (car visited-ref))))
    (push node-id (car visited-ref))
    (let* ((node (org-roam-node-from-id node-id))
           (title (org-roam-node-title node))
           (file (org-roam-node-file node))
           ;; Find outgoing links from this node
           (children (org-roam-db-query
                      [:select [dest] :from links :where (= source $s1) :and (= type "id")]
                      node-id)))
      ;; Insert current node as a button
      (insert prefix connector)
      (insert-button title
                     'action (lambda (btn)
                               (let ((file (button-get btn 'file)))
                                 (kill-buffer (current-buffer))
                                 (find-file file)))
                     'file file
                     'face 'org-roam-link
                     'help-echo (concat "Open " title))
      (insert "\n")
      ;; Process children
      (let ((child-count (length children)))
        (dotimes (i child-count)
          (let* ((child-id (car (nth i children)))
                 (is-last (= i (1- child-count)))
                 (child-connector (if is-last "└── " "├── "))
                 (child-next (if is-last "    " "│   ")))
            (boba-roam-text-graph-insert child-id
                                         visited-ref
                                         (1+ level)
                                         (concat prefix next-prefix)
                                         child-connector
                                         child-next)))))))

(defun boba-roam-text-graph (&optional node)
  "Generate an interactive, hierarchical text-based graph starting from NODE."
  (interactive)
  (let* ((node (or node
                   (and (derived-mode-p 'org-mode)
                        (org-roam-file-p)
                        (org-roam-node-at-point))
                   (org-roam-node-read nil nil nil t)))
         (node-id (org-roam-node-id node))
         (buf (get-buffer-create "*Org Roam Text Graph*"))
         (visited-ref (cons nil nil)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (special-mode)
        (insert (propertize "Org-roam Text Graph Map\n" 'face 'theme-face-title))
        (insert (propertize "=======================\n" 'face 'theme-face-faded))
        (insert (propertize "Click or press RET on any node to jump to it.\n\n" 'face 'theme-face-faded))
        (boba-roam-text-graph-insert node-id visited-ref 0 "" "" "")
        (goto-char (point-min))))
    (pop-to-buffer buf)))

;; Keybindings using general.el leader
(with-eval-after-load 'general
  (general-define-key
   :states '(normal insert visual motion)
   :keymaps 'override
   :prefix "SPC"
   :global-prefix "C-SPC"
   "r"   '(:ignore t :which-key "roam")
   "r f" '(org-roam-node-find :which-key "Find node")
   "r i" '(org-roam-node-insert :which-key "Insert node link")
   "r g" '(org-roam-ui-mode :which-key "Toggle graph view")
   "r G" '(org-roam-graph :which-key "Native graph view")
   "r T" '(boba-roam-text-graph :which-key "Interactive text graph")
   "r b" '(boba-sidebar-toggle-org :which-key "Toggle backlinks sidebar")
   "r d" '(org-roam-dailies-goto-today :which-key "Today's daily note")
   "r y" '(org-roam-dailies-goto-yesterday :which-key "Yesterday's daily note")
   "r t" '(org-roam-dailies-goto-tomorrow :which-key "Tomorrow's daily note")
   "r c" '(org-roam-capture :which-key "Roam capture")))

;; Aesthetic visual styling for Org-roam node links
(defface org-roam-link
  `((t (:inherit theme-face-salient :weight bold :underline nil)))
  "Face for Org-roam ID links."
  :group 'org-roam)

(with-eval-after-load 'org
  (org-link-set-parameters "id" :face 'org-roam-link))

(provide 'syntax/org-roam)
;;; org-roam.el ends here
