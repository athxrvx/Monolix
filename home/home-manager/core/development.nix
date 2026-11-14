{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Source control and project archives.
    git
    wget
    unzip
    # Editors and language toolchains already used by this setup.
    emacs-pgtk
    gcc
    gnumake
    pkg-config
    python3
    rustc
    cargo

    # Search, inspection, and codebase analysis.
    ripgrep
    fd
    bat
    tokei

    # Android and Flutter. Android Studio manages the licensed SDK components
    # through its SDK Manager; no Android SDK license is accepted implicitly.
    android-studio
    android-tools
    flutter
    jdk17
    gradle
    jdt-language-server
    kotlin-language-server
    nixd
    python3Packages.python-lsp-server
    rust-analyzer
    gopls
    clang-tools
    typescript-language-server
    shellcheck
    shfmt
    jq
    cmake
    ninja
    vscode

    # Containerization
    podman
    distrobox

  ];

  imports = [
      ../config/development/zed.nix
      ../config/development/opencode.nix
  ];

  home.sessionVariables = {
    ANDROID_HOME = "$HOME/Android/Sdk";
    ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
    JAVA_HOME = "${pkgs.jdk17}";
  };
}
