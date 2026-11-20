# Small interactive comforts; these do not replace or wrap standard commands.
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias l='ls -CF --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
alias grep='grep --color=auto'

function mkcd() {
  [[ -n "$1" ]] || { print -u2 'usage: mkcd DIRECTORY'; return 2; }
  command mkdir -p -- "$1" && builtin cd -- "$1"
}

function croot() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return
  builtin cd -- "$root"
}
