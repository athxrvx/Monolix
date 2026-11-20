;;; macros.el --- Atomic Emacs module -*- lexical-binding: t; -*-

;;;; Anaphora
;; Useful macro library: Anaphoric expressions implicitly create one or more
;; temporary variables which can be referred to during the expression. This
;; technique can improve clarity in certain cases. It also enables recursion for
;; anonymous functions.
(use-package anaphora
  :when (and lem-load-extras (locate-library "anaphora")) :defer 1)

;;;; Toggle macro

(defun deftoggle-var-doc (name)
  (concat "Non-nil if " name " is enabled.\n\n"
          "See " name
          " command for a description of this toggle."))
(defun deftoggle-fun-doc (name doc)
  (concat "Toggle " name " on or off.\n\n" doc))

(defmacro deftoggle (name doc enabler disabler)
  `(progn
     (defvar ,name nil ,(deftoggle-var-doc (symbol-name name)))
     (defun ,name (&optional enable)
       ,(deftoggle-fun-doc (symbol-name name) doc)
       (interactive)
       (if (called-interactively-p 'interactive)
           (progn
             (if ,name
                 ,disabler
               ,enabler)
             (setq ,name (not ,name)))
         (progn
           (if enable
               ,enabler
             ,disabler)
           (setq ,name enable))))))
;; It's very similar to define-minor-mode, but with all the hooks, keymaps, and lighters stripped out, so it's less verbose. Here I use it to toggle my theme for example:
;; (deftoggle sam-toggle-theme
;;   "Toggle theme between light and dark."
;;   (progn (disable-theme 'dracula)
;;          (load-theme 'spacemacs-light t))
;;   (progn (disable-theme 'spacemacs-light)
;;          (load-theme 'dracula t)))

;;;; Set Variables
;; This is a useful catch-all macro for setting variables.
;; Originally from https://oremacs.com/2015/01/17/setting-up-ediff/
;; Revised multi-form version from https://discord.com/channels/767406463265538068/986709779995066428/986726251941212223

(defmacro csetq (&rest forms)
  "Bind each custom variable FORM to the value of its VAL.

FORMS is a list of pairs of values [FORM VAL].

If FORM has a custom setter, use it to set FORM to VAL.
Otherwise, use `set-default'.

\(fn [FORM VAL]...)"
  (declare (debug (&rest sexp form))
           (indent 1))
  ;; Check if we have an even number of arguments
  (when (= (mod (length forms) 2) 1)
    (signal 'wrong-number-of-arguments (list 'csetq (1+ (length forms)))))
  ;; Transform FORMS into a list of pairs (FORM . VALUE)
  `(progn ,@(cl-loop for (form value) on forms by 'cddr
                     collect `(customize-set-variable ',form ,value))))

(provide 'component/macros)

;;; lem-setup-macros.el ends here
