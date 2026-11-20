# zsh-autosuggestions is installed and sourced by Home Manager
# (programs.zsh.autosuggestion.enable). Keep only Kuro's preferred styling
# and accept binding here; no native fallback is needed.
[[ ! -o interactive ]] && return

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^@' autosuggest-accept 2>/dev/null || true
