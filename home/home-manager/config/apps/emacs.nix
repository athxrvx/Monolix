{ boba, config, pkgs, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
  emacsTreesitGrammars = pkgs.emacsPackages.treesit-grammars.with-grammars (grammars: [
    grammars.tree-sitter-bash
    grammars.tree-sitter-c
    grammars.tree-sitter-cpp
    grammars.tree-sitter-css
    grammars.tree-sitter-dart
    grammars.tree-sitter-go
    grammars.tree-sitter-html
    grammars.tree-sitter-java
    grammars.tree-sitter-javascript
    grammars.tree-sitter-json
    grammars.tree-sitter-kotlin
    grammars.tree-sitter-markdown
    grammars.tree-sitter-nix
    grammars.tree-sitter-python
    grammars.tree-sitter-rust
    grammars.tree-sitter-toml
    grammars.tree-sitter-typescript
    grammars.tree-sitter-yaml
  ]);
  emacsYoruTheme = pkgs.writeText "monolix-yoru-theme.el" ''
    ;;; monolix-yoru-theme.el --- Monolix Yoru colors for Boba -*- lexical-binding: t; -*-
    (deftheme monolix-yoru "Monolix Yoru, using the active Stylix palette.")
    (let ((bg "${colors.base00}")
          (surface "${colors.base01}")
          (raised "${colors.base02}")
          (border "${colors.base04}")
          (muted "${colors.base06}")
          (fg "${colors.base05}")
          (red "${colors.base08}")
          (yellow "${colors.base09}")
          (orange "${colors.base0A}")
          (green "${colors.base0B}")
          (teal "${colors.base0C}")
          (blue "${colors.base0D}")
          (purple "${colors.base0E}")
          (pink "${colors.base0F}"))
      (custom-theme-set-faces
       'monolix-yoru
       `(default ((t (:foreground ,fg :background ,bg))))
       `(cursor ((t (:background ,blue))))
       `(fringe ((t (:foreground ,muted :background ,bg))))
       `(border ((t (:foreground ,border))))
       `(window-divider ((t (:foreground ,border :background ,bg))))
       `(vertical-border ((t (:foreground ,border))))
       `(region ((t (:foreground ,fg :background ,border))))
       `(highlight ((t (:background ,raised))))
       `(hl-line ((t (:background ,surface))))
       `(secondary-selection ((t (:background ,border))))
       `(shadow ((t (:foreground ,muted))))
       `(minibuffer-prompt ((t (:foreground ,blue :weight bold))))
       `(link ((t (:foreground ,teal :underline t))))
       `(link-visited ((t (:foreground ,purple :underline t))))
       `(button ((t (:foreground ,blue :underline nil))))
       `(isearch ((t (:foreground ,bg :background ,yellow :weight bold))))
       `(lazy-highlight ((t (:foreground ,fg :background ,raised))))
       `(match ((t (:foreground ,bg :background ,green))))
       `(error ((t (:foreground ,red :weight bold))))
       `(warning ((t (:foreground ,yellow))))
       `(success ((t (:foreground ,green))))
       `(mode-line ((t (:foreground ,fg :background ,surface :box (:line-width 1 :color ,border)))))
       `(mode-line-inactive ((t (:foreground ,muted :background ,surface :box (:line-width 1 :color ,border)))))
       `(header-line ((t (:foreground ,fg :background ,surface :box (:line-width 1 :color ,border)))))
       `(line-number ((t (:foreground ,muted :background ,bg))))
       `(line-number-current-line ((t (:foreground ,blue :background ,bg :weight bold))))
       `(font-lock-comment-face ((t (:foreground ,muted :slant italic))))
       `(font-lock-doc-face ((t (:foreground ,muted))))
       `(font-lock-string-face ((t (:foreground ,green))))
       `(font-lock-constant-face ((t (:foreground ,orange))))
       `(font-lock-function-name-face ((t (:foreground ,blue :weight medium))))
       `(font-lock-variable-name-face ((t (:foreground ,fg))))
       `(font-lock-builtin-face ((t (:foreground ,teal))))
       `(font-lock-type-face ((t (:foreground ,yellow))))
       `(font-lock-keyword-face ((t (:foreground ,purple :weight medium))))
       `(font-lock-warning-face ((t (:foreground ,red :weight bold))))
       ;; Boba's dashboard builds its cards from these semantic faces. Define
       ;; them in the theme itself so its old global face defaults cannot win.
       `(theme-face-default ((t (:foreground ,fg :background ,bg))))
       `(theme-face-variable-pitch ((t (:foreground ,fg :background ,bg))))
       `(theme-face-strong ((t (:foreground ,fg :weight medium))))
       `(theme-face-faded ((t (:foreground ,muted))))
       `(theme-face-subtle ((t (:foreground ,fg :background ,raised))))
       `(theme-face-salient ((t (:foreground ,blue))))
       `(theme-face-popout ((t (:foreground ,yellow))))
       `(theme-face-critical ((t (:foreground ,red))))
       `(dashboard-button-face ((t (:foreground ,blue :background ,surface :weight bold))))
       `(dashboard-border-face ((t (:foreground ,border))))
       `(dashboard-title-face ((t (:foreground ,blue :weight bold))))
       `(dashboard-stats-face ((t (:foreground ,muted))))
       `(dashboard-card-header-face ((t (:foreground ,fg :background ,surface :weight bold))))
       `(dashboard-separator-face ((t (:foreground ,border))))
       `(dashboard-modeline-button-hover-face
         ((t (:foreground ,blue :background ,raised :box (:line-width 1 :color ,blue)))))
       `(custom-button ((t (:foreground ,fg :background ,raised :box (:line-width 1 :color ,border)))))
       `(widget-field ((t (:foreground ,fg :background ,surface :box (:line-width 1 :color ,border)))))
       `(widget-single-line-field ((t (:foreground ,fg :background ,surface :box (:line-width 1 :color ,border)))))
       `(org-block ((t (:foreground ,fg :background ,surface))))
       `(org-code ((t (:foreground ,teal))))
       `(org-verbatim ((t (:foreground ,purple))))
       `(org-level-1 ((t (:foreground ,blue :weight bold))))
       `(org-level-2 ((t (:foreground ,purple :weight bold))))
       `(org-level-3 ((t (:foreground ,teal :weight bold))))
       `(org-level-4 ((t (:foreground ,green :weight bold))))
       `(org-todo ((t (:foreground ,red :weight bold))))
       `(org-done ((t (:foreground ,green :weight bold)))))
      (custom-theme-set-variables
       'monolix-yoru
       '(frame-background-mode 'dark)))
    (provide-theme 'monolix-yoru)
    ;;; monolix-yoru-theme.el ends here
  '';
in
{
  xdg.configFile = {
    "emacs/early-init.el".source = "${boba}/early-init.el";
    "emacs/init.el".source = "${boba}/init.el";
    # Boba's checked-in Org block face is hard-coded to its light palette.
    # Replace that one background so it follows the active Stylix scheme.
    "emacs/custom.el".text = builtins.replaceStrings
      [ "#F7F3EE" ] [ colors.base00 ]
      (builtins.readFile "${boba}/custom.el");
    "emacs/lisp".source = "${boba}/lisp";
    "emacs/assets".source = "${boba}/assets";
    "emacs/bin".source = "${boba}/bin";
    "emacs/themes/monolix-yoru-theme.el".source = emacsYoruTheme;
    # Boba loads this before its main init. Mark it lexical so Emacs does not
    # leave the startup warning buffer open on every launch.
    "boba/config.el".text = ''
      ;;; -*- lexical-binding: t; -*-

      ;; Keep Boba's upstream configuration and layer the Monolix IDE setup on top.
      (load-file "${boba}/custom.el")

      (defun monolix-apply-stylix-colors (&rest _)
        "Apply the active Home Manager Stylix palette to Boba's semantic colors."
        ;; Boba's enabled theme has explicit face specs which outrank the
        ;; semantic palette. Disable it before refreshing those faces.
        (dolist (theme '(boba boba-dark))
          (when (memq theme custom-enabled-themes)
            (disable-theme theme)))
        (setq frame-background-mode '${if config.stylix.polarity == "light" then "light" else "dark"}
              theme-color-background "${colors.base00}"
              theme-color-subtle "${colors.base01}"
              theme-color-highlight "${colors.base02}"
              ;; In Yoru, base04 is a dark border shade, not muted text.
              theme-color-faded "${colors.base06}"
              theme-color-foreground "${colors.base05}"
              theme-color-strong "${colors.base06}"
              theme-color-critical "${colors.base08}"
              theme-color-popout "${colors.base09}"
              theme-color-salient "${colors.base0D}"
              theme-color-modeline-bg "${colors.base01}"
              theme-font-family-monospaced "${config.stylix.fonts.monospace.name}"
              theme-font-family-proportional "${config.stylix.fonts.sansSerif.name}"
              theme-font-size 11)
        (add-to-list 'custom-theme-load-path
                     (expand-file-name "themes" user-emacs-directory))
        (unless (memq 'monolix-yoru custom-enabled-themes)
          (load-theme 'monolix-yoru t))
        (when (display-graphic-p)
          (set-face-attribute 'default nil :family theme-font-family-monospaced
                              :height (* theme-font-size 10)))
        (when (fboundp 'theme-refresh)
          (theme-refresh)))

      ;; Boba refreshes all derived faces from these variables. Set them first,
      ;; so its own theme and refresh commands always follow the selected palette.
      (with-eval-after-load 'ui/theme
        (monolix-apply-stylix-colors))

      ;; Keep Stylix authoritative if Boba's light/dark toggle loads its own
      ;; fixed-color theme later, and refresh colors for frames created by the daemon.
      (with-eval-after-load 'ui/theme
        (advice-add 'theme-toggle :after #'monolix-apply-stylix-colors))
      (add-hook 'after-make-frame-functions #'monolix-apply-stylix-colors)

      (defun monolix-project-root ()
        "Find the nearest Flutter or Android project root."
        (or (locate-dominating-file default-directory "pubspec.yaml")
            (locate-dominating-file default-directory "gradlew")
            (locate-dominating-file default-directory "settings.gradle")
            (locate-dominating-file default-directory "settings.gradle.kts")
            (locate-dominating-file default-directory "build.gradle")
            (locate-dominating-file default-directory "build.gradle.kts")
            default-directory))

      (defun monolix-project-try-root (directory)
        "Recognize Flutter and Gradle projects for project.el."
        (when-let ((root
                    (locate-dominating-file
                     directory
                     (lambda (dir)
                       (or (file-exists-p (expand-file-name "pubspec.yaml" dir))
                           (file-exists-p (expand-file-name "gradlew" dir))
                           (file-exists-p (expand-file-name "settings.gradle" dir))
                           (file-exists-p (expand-file-name "settings.gradle.kts" dir))
                           (file-exists-p (expand-file-name "build.gradle" dir))
                           (file-exists-p (expand-file-name "build.gradle.kts" dir)))))))
          (cons 'monolix-project root)))

      (cl-defmethod project-root ((project (head monolix-project)))
        "Return the detected root of a Monolix project."
        (cdr project))

      (defun monolix-programming-setup ()
        "Use consistent, code-focused editing defaults in programming buffers."
        (setq-local indent-tabs-mode nil
                    tab-width 4
                    fill-column 100
                    show-trailing-whitespace t)
        (electric-pair-local-mode 1)
        (when (fboundp 'rainbow-delimiters-mode)
          (rainbow-delimiters-mode 1)))

      (defun monolix-project-search ()
        "Search the current project with ripgrep."
        (interactive)
        (consult-ripgrep (project-root (project-current t))))

      (defun monolix-project-compile ()
        "Run the project's compile command from its root."
        (interactive)
        (let ((default-directory (project-root (project-current t))))
          (call-interactively #'compile)))

      (defun monolix-compile-in-project (command)
        (let ((default-directory (monolix-project-root)))
          (compile command)))

      (defun monolix-flutter-run ()
        "Run Flutter with an interactive terminal for device selection and logs."
        (interactive)
        (let ((default-directory (monolix-project-root)))
          (pop-to-buffer
           (make-comint-in-buffer "Flutter Run" "*Flutter Run*" "flutter" nil "run"))))

      (defun monolix-flutter-test ()
        (interactive)
        (monolix-compile-in-project "flutter test"))

      (defun monolix-flutter-build ()
        (interactive)
        (monolix-compile-in-project "flutter build apk --debug"))

      (defun monolix-android-build ()
        (interactive)
        (monolix-compile-in-project "./gradlew assembleDebug"))

      (defun monolix-android-test ()
        (interactive)
        (monolix-compile-in-project "./gradlew test"))

      (defun monolix-android-studio ()
        "Open the current Android or Flutter project in Android Studio."
        (interactive)
        (start-process "Android Studio" nil "android-studio"
                       (monolix-project-root)))

      (defun monolix-ai-panel ()
        "Open the persistent right-side AI chat panel."
        (interactive)
        (require 'gptel)
        (let ((buffer (get-buffer-create "*Monolix AI*")))
          (with-current-buffer buffer
            (unless (derived-mode-p 'gptel-mode)
              (gptel-mode))
            (setq-local gptel-model 'gpt-5.4-mini))
          (select-window
           (display-buffer-in-side-window
            buffer '((side . right) (window-width . 0.36) (slot . 0))))))

      ;; Boba loads its modules after this file; install IDE extensions once its
      ;; package manager and leader-key definitions are ready.
      (with-eval-after-load 'init
        (dolist (package '(dart-mode kotlin-mode nix-mode gptel))
          (straight-use-package package))
        (require 'dart-mode)
        (require 'kotlin-mode)
        (require 'nix-mode)
        (require 'gptel)
        (require 'gptel-openai-oauth)
        (setq-default indent-tabs-mode nil
                      tab-width 4
                      scroll-conservatively 101
                      scroll-margin 3)
        (setq display-line-numbers-type 'relative
              project-switch-commands
              '((project-find-file "Find file")
                (project-dired "Browse files")
                (project-eshell "Project shell")
                (compile "Compile"))
              compilation-scroll-output 'first-error
              auto-revert-verbose nil
              global-auto-revert-non-file-buffers t)
        (global-display-line-numbers-mode 1)
        (global-hl-line-mode 1)
        (global-auto-revert-mode 1)
        (save-place-mode 1)
        (savehist-mode 1)
        (recentf-mode 1)
        (add-hook 'prog-mode-hook #'monolix-programming-setup)
        (add-to-list 'project-find-functions #'monolix-project-try-root)
        (add-hook 'dart-mode-hook #'eglot-ensure)
        (add-hook 'kotlin-mode-hook #'eglot-ensure)
        (add-hook 'nix-mode-hook #'eglot-ensure)
        (add-hook 'nix-ts-mode-hook #'eglot-ensure)
        (add-hook 'dart-mode-hook (lambda () (setq-local tab-width 2)))
        (add-hook 'kotlin-mode-hook (lambda () (setq-local tab-width 4)))
        (add-hook 'java-mode-hook (lambda () (setq-local tab-width 4)))
        (with-eval-after-load 'eglot
          (add-to-list 'eglot-server-programs
                       '((dart-mode) . ("dart" "language-server" "--protocol=lsp")))
          (add-to-list 'eglot-server-programs
                       '((java-mode java-ts-mode) . ("jdtls")))
          (add-to-list 'eglot-server-programs
                       '((kotlin-mode) . ("kotlin-language-server")))
          (add-to-list 'eglot-server-programs
                       '((nix-mode nix-ts-mode) . ("nixd")))
          (add-to-list 'eglot-server-programs
                       '((python-mode python-ts-mode) . ("pylsp" "--")))
          (add-to-list 'eglot-server-programs
                       '((rust-mode rust-ts-mode) . ("rust-analyzer")))
          (add-to-list 'eglot-server-programs
                       '((js-mode js-ts-mode typescript-mode typescript-ts-mode)
                         . ("typescript-language-server" "--stdio")))
          (add-to-list 'eglot-server-programs
                       '((c-mode c-ts-mode c++-mode c++-ts-mode)
                         . ("clangd" "--header-insertion=never" "--completion-style=detailed")))
          (add-to-list 'eglot-server-programs
                       '((go-mode go-ts-mode) . ("gopls"))))
        (setq gptel-default-mode 'markdown-mode
              gptel-model 'gpt-5.4-mini
              gptel-backend (gptel-make-openai-oauth "ChatGPT")
              gptel-use-curl t)
        (add-to-list 'display-buffer-alist
                     '("\\*Monolix AI\\*"
                       (display-buffer-in-side-window)
                       (side . right) (window-width . 0.36) (slot . 0)))
        (with-eval-after-load 'general
          (my-leader
            "p s" '(monolix-project-search :which-key "Search project")
            "p c" '(monolix-project-compile :which-key "Compile project")
            "p t" '(project-eshell :which-key "Project terminal")
            "e"   '(:ignore t :which-key "evaluate / execute")
            "e b" '(eval-buffer :which-key "Evaluate buffer")
            "e e" '(eval-last-sexp :which-key "Evaluate expression")
            "c"   '(:ignore t :which-key "code")
            "c c" '(monolix-project-compile :which-key "Compile project")
            "c f" '(eglot-format-buffer :which-key "Format buffer")
            "c x" '(consult-flymake :which-key "Diagnostics")
            "c n" '(flymake-goto-next-error :which-key "Next diagnostic")
            "c p" '(flymake-goto-prev-error :which-key "Previous diagnostic")
            "l"   '(:ignore t :which-key "language server")
            "l a" '(eglot-code-actions :which-key "Code actions")
            "l d" '(xref-find-definitions :which-key "Go to definition")
            "l r" '(eglot-rename :which-key "Rename symbol")
            "l s" '(eglot-workspace-symbols :which-key "Workspace symbols")
            "l R" '(eglot-reconnect :which-key "Reconnect server")
            "g g" '(magit-status :which-key "Git status")
            "m"   '(:ignore t :which-key "mobile development")
            "m r" '(monolix-flutter-run :which-key "Run Flutter app")
            "m t" '(monolix-flutter-test :which-key "Test Flutter app")
            "m b" '(monolix-flutter-build :which-key "Build Flutter APK")
            "m a" '(monolix-android-build :which-key "Build Android app")
            "m x" '(monolix-android-test :which-key "Test Android app")
            "m o" '(monolix-android-studio :which-key "Open in Android Studio")
            "a"   '(:ignore t :which-key "AI")
            "a a" '(monolix-ai-panel :which-key "Open AI side panel")
            "a l" '(gptel-openai-oauth-login :which-key "Sign in to ChatGPT")
            "a s" '(gptel-send :which-key "Send AI prompt"))))
    '';
  };

  # Boba's programming module expects native grammars in this directory. A
  # read-only link keeps them reproducible and avoids runtime downloads/builds.
  xdg.configFile."emacs/tree-sitter".source = "${emacsTreesitGrammars}/lib";

  # Run one user Emacs daemon so terminal editors and GUI frames share the same
  # IDE session, buffers, and project state.
  systemd.user.services.emacs = {
    Unit = {
      Description = "Emacs IDE daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.emacs-pgtk}/bin/emacs --fg-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
