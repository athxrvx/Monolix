# zsh-syntax-highlighting is installed and sourced by Home Manager
# (programs.zsh.syntaxHighlighting.enable). This file only sets Kuro's
# colors before the packaged plugin is loaded; no native fallback is needed.
[[ ! -o interactive ]] && return

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=5,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=6,bold'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=8'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=6'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=5'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=2,bold'
