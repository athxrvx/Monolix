;;; session.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(defvar boba-data-dir
  (expand-file-name "boba" (or (getenv "XDG_DATA_HOME") "~/.local/share"))
  "Directory for Bobamacs data files (recentf, savehist, bookmarks, etc.).")

(defun boba-ensure-data-dir ()
  "Ensure Bobamacs data directory exists."
  (unless (file-directory-p boba-data-dir)
    (make-directory boba-data-dir t)))

(boba-ensure-data-dir)

(setq savehist-additional-variables
      '(kill-ring
        command-history
	set-variable-value-history
	custom-variable-history   
	query-replace-history     
	read-expression-history   
	minibuffer-history        
	read-char-history         
	face-name-history         
	bookmark-history          
        ivy-history               
	counsel-M-x-history       
	file-name-history         
        counsel-minibuffer-history))
(setq history-length 250)
(setq kill-ring-max 25)
(put 'minibuffer-history         'history-length 50)
(put 'file-name-history          'history-length 50)
(put 'set-variable-value-history 'history-length 25)
(put 'custom-variable-history    'history-length 25)
(put 'query-replace-history      'history-length 25)
(put 'read-expression-history    'history-length 25)
(put 'read-char-history          'history-length 25)
(put 'face-name-history          'history-length 25)
(put 'bookmark-history           'history-length 25)
(put 'ivy-history                'history-length 25)
(put 'counsel-M-x-history        'history-length 25)
(put 'counsel-minibuffer-history 'history-length 25)
(setq savehist-file (expand-file-name "savehist" boba-data-dir))
(savehist-mode 1)

;; Remove text properties for kill ring entries
;; See https://emacs.stackexchange.com/questions/4187
(defun unpropertize-kill-ring ()
  (setq kill-ring (mapcar 'substring-no-properties kill-ring)))
(add-hook 'kill-emacs-hook 'unpropertize-kill-ring)

;; Recentf files 
(setq recentf-max-menu-items 25)
(setq recentf-save-file (expand-file-name "recentf" boba-data-dir))
(recentf-mode 1)

;; Bookmarks
(setq bookmark-default-file (expand-file-name "bookmark" boba-data-dir))


;; Backup
(setq backup-directory-alist `(("." . ,(expand-file-name "backups" boba-data-dir)))
      make-backup-files t     ; backup of a file the first time it is saved.
      backup-by-copying t     ; don't clobber symlinks
      version-control t       ; version numbers for backup files
      delete-old-versions t   ; delete excess backup files silently
      kept-old-versions 6     ; oldest versions to keep when a new numbered
                              ;  backup is made (default: 2)
      kept-new-versions 9     ; newest versions to keep when a new numbered
                              ;  backup is made (default: 2)
      auto-save-default t     ; auto-save every buffer that visits a file
      auto-save-timeout 20    ; number of seconds idle time before auto-save
                              ;  (default: 30)
      auto-save-interval 200)  ; number of keystrokes between auto-saves
                              ;  (default: 300)

;; Auto-save list
(setq auto-save-list-file-prefix (expand-file-name "auto-save-list/" boba-data-dir))

(provide 'ui/session)
