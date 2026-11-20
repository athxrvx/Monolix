;;; lsp.el --- Eglot LSP, Corfu completions, and Tree-sitter -*- lexical-binding: t; -*-

(use-package eglot
  :straight nil
  :hook
  ((prog-mode . eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0
        eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider)
        eglot-autoshutdown t))

(use-package corfu
  :config
  (global-corfu-mode 1)
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-quit-at-boundary nil
        corfu-quit-no-match 'separator
        corfu-preselect 'prompt)

  (defun corfu-enable-in-minibuffer ()
    (when (local-variable-p 'completing-read-function)
      (setq-local corfu-auto nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-in-minibuffer))

(use-package nerd-icons-corfu
  :after corfu
  :init
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package treesit
  :straight nil
  :config
  (setq treesit-font-lock-level 4)
  (setq treesit-language-source-alist
        '((bash "https://github.com/tree-sitter/tree-sitter-bash")
          (css "https://github.com/tree-sitter/tree-sitter-css")
          (elisp "https://github.com/Wilfred/tree-sitter-elisp")
          (html "https://github.com/tree-sitter/tree-sitter-html")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (markdown "https://github.com/ikatyang/tree-sitter-markdown")
          (python "https://github.com/tree-sitter/tree-sitter-python")
          (rust "https://github.com/tree-sitter/tree-sitter-rust")
          (toml "https://github.com/ikatyang/tree-sitter-toml")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
          (yaml "https://github.com/ikatyang/tree-sitter-yaml"))))

(use-package rust-mode
  :straight t
  :mode "\\.rs\\'"
  :init
  (when (and (fboundp 'treesit-ready-p)
             (treesit-ready-p 'rust))
    (add-to-list 'major-mode-remap-alist '(rust-mode . rust-ts-mode))))

(provide 'code/lsp)
;;; lsp.el ends here
