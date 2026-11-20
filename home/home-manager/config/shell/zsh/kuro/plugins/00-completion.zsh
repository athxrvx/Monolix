# Completion setup with a local completion directory and persistent cache.
# Host and distrobox share $HOME, so keep separate compdumps to avoid
# cross-version cache corruption (NixOS zsh vs Ubuntu zsh).
[[ -d "$ZSH_CONFIG_HOME/completions" ]] && fpath=("$ZSH_CONFIG_HOME/completions" $fpath)
autoload -Uz compinit
[[ -d "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}" ]] || mkdir -p "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}" 2>/dev/null
if [[ -n "${DISTROBOX_NAME:-}" || -f /.dockerenv || -f /run/.containerenv || -n "${container:-}" ]]; then
    _kuro_compdump="${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}/zcompdump-container-${ZSH_VERSION}"
else
    _kuro_compdump="${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}/zcompdump-${ZSH_VERSION}"
fi
compinit -C -u -d "$_kuro_compdump"
unset _kuro_compdump

setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_LIST
setopt NO_BEEP
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}/completion"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
