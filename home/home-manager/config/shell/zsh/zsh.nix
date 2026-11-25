{ config, pkgs, ... }:
{
  # Declarative PATH + zsh locations (no hand-written zshenv). These were
  # previously set in the imperative kuro/zshenv; Kuro's plugins and theme
  # resolve everything through ZSH_CONFIG_HOME / ZSH_CACHE_DIR.
  home.sessionPath = [ "${config.xdg.configHome}/zsh/bin" ];
  home.sessionVariables = {
    ZSH_CONFIG_HOME = "${config.xdg.configHome}/zsh";
    ZSH_CACHE_DIR = "${config.xdg.configHome}/zsh/cache";
  };
  home.packages = [ pkgs.any-nix-shell ];

  # Use the packaged zoxide integration instead of Kuro's native fallback,
  # which shelled out to sort/head/mv on every cd and broke with a bad PATH.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = false;
    defaultKeymap = "viins";
    autocd = true;
    dotDir = "${config.xdg.configHome}/zsh";
    shellAliases = import ./alias.nix;
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh_history";
      share = true;
      ignoreDups = true;
      extended = true;
    };
    initContent = ''
      setopt AUTO_CD HIST_FCNTL_LOCK HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_VERIFY INTERACTIVE_COMMENTS NO_BEEP
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Completion is initialised once by kuro's 00-completion.zsh (compinit -C -u).
      # Nix store paths are group/other-writable, which compinit flags as
      # insecure; kuro's plugin already passes -u so distrobox containers work.

      # Kuro's plugins, prompt and generated palette (from ~/.cache/kuro).
      [[ -r "$HOME/.config/zsh/zshrc" ]] && source "$HOME/.config/zsh/zshrc"

      # Keep nix-shell and nix run interactive sessions on this same Zsh setup.
      # --info-right replaces RPROMPT every prompt and hides Kuro's right-side indicators.
      ${pkgs.any-nix-shell}/bin/any-nix-shell zsh | source /dev/stdin
    '';
  };

}
