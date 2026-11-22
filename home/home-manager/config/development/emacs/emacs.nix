{ pkgs, ... }:
let
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
in
{
  home.packages = with pkgs; [
    emacs-pgtk
    # Build tools required by straight.el and runtime packages
    cmake
    gnumake
    gcc
  ];

  # Bobamacs configuration files linked into ~/.config/emacs.
  # Individual files and directories are linked so that ~/.config/emacs itself
  # remains a writable directory for straight.el, eln-cache, and runtime state.
  xdg.configFile = {
    "emacs/early-init.el".source = ./early-init.el;
    "emacs/init.el".source = ./init.el;
    "emacs/custom.el".source = ./custom.el;
    "emacs/lisp".source = ./lisp;
    "emacs/assets".source = ./assets;
    "emacs/bin".source = ./bin;
    "emacs/tree-sitter".source = "${emacsTreesitGrammars}/lib";
  };

  # Make boba CLI accessible in user's PATH
  home.sessionPath = [
    "$HOME/.config/emacs/bin"
  ];

  # Run user Emacs daemon for fast instant startup and shared buffers
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
