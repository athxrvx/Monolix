# A restrained dark FZF palette that follows Kuro's accent and muted tones.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --layout=reverse --border=rounded --margin=1 --padding=1 --info=inline --prompt='❯ ' --pointer='▶' --marker='✓' --color=bg:#0d0d0d,bg+:#1b2023,fg:#dedede,fg+:#ffffff,hl:#97bedc,hl+:#b1d8f6,info:#888888,border:#303030,prompt:#8a694c,pointer:#ffa560,marker:#94b979,spinner:#e1c0fa,header:#888888"

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude .cache'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude .cache'
elif (( $+commands[rg] )); then
  export FZF_DEFAULT_COMMAND='rg --files --hidden -g "!.git" -g "!.cache"'
fi

export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS:-} --preview '([[ -d {} ]] && ls -la --color=always {} || (command -v bat >/dev/null && bat --color=always --style=numbers --line-range :120 {} || sed -n "1,120p" {})) 2>/dev/null' --preview-window='right,60%,border-left'"
export FZF_ALT_C_OPTS="${FZF_ALT_C_OPTS:-} --preview 'ls -la --color=always {} 2>/dev/null' --preview-window='right,50%,border-left'"

# fzf shell integration: lazy-loaded on first widget use, not at shell start.
_kuro_fzf_ready=0

_kuro_fzf_init() {
    (( _kuro_fzf_ready )) && return 0
    _kuro_fzf_ready=1
    if (( $+commands[fzf] )); then
        local _kuro_fzf_init
        _kuro_fzf_init="$(fzf --zsh 2>/dev/null)" && eval "$_kuro_fzf_init"
        unset _kuro_fzf_init
    fi
}

# Lazy widget wrappers: init fzf on first use, then dispatch to the real widget.
_kuro_fzf_history() { _kuro_fzf_init; fzf-history-widget "$@"; }
_kuro_fzf_file()    { _kuro_fzf_init; fzf-file-widget    "$@"; }
_kuro_fzf_cd()      { _kuro_fzf_init; fzf-cd-widget      "$@"; }
zle -N fzf-history-widget _kuro_fzf_history
zle -N fzf-file-widget    _kuro_fzf_file
zle -N fzf-cd-widget      _kuro_fzf_cd

bindkey '^R' fzf-history-widget
bindkey '^T' fzf-file-widget
bindkey '\ec' fzf-cd-widget 2>/dev/null || true

function fcd() {
  (( $+commands[fzf] )) || { print -u2 'fcd needs fzf'; return 127; }
  local dir
  dir="$(FZF_DEFAULT_COMMAND="${FZF_ALT_C_COMMAND:-find . -type d -not -path '*/.git*'}" fzf --query="$*" --preview='ls -la --color=always {} 2>/dev/null')" || return
  [[ -n "$dir" ]] && builtin cd -- "$dir"
}

function fopen() {
  (( $+commands[fzf] )) || { print -u2 'fopen needs fzf'; return 127; }
  local selected
  selected="$(fzf --query="$*" --multi --preview='([[ -d {} ]] && ls -la --color=always {} || (command -v bat >/dev/null && bat --color=always --style=numbers --line-range :120 {} || sed -n "1,120p" {})) 2>/dev/null')" || return
  [[ -n "$selected" ]] || return 0
  local editor="${EDITOR:-hx}"
  ${=editor} "${(@f)selected}"
}
