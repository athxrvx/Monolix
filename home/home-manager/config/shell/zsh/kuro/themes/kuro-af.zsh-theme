# Kuro Af-Magic — the classic af-magic layout (Andy Fleming) in Kuro's palette.
#   line 1 : full-width dashed rule
#   line 2 : green path + git info + # / » glyph
#   right  : exit status + virtualenv + container/imperative + user@host
# Colours are optional overrides from kurogen's ~/.cache/kuro/zsh-colors.zsh.

[[ -r "$HOME/.cache/kuro/zsh-colors.zsh" ]] && source "$HOME/.cache/kuro/zsh-colors.zsh"

: ${KURO_PROMPT_RULE:=#454545}
: ${KURO_PROMPT_PATH:=#94b979}
: ${KURO_PROMPT_GLYPH:=#e1c0fa}
: ${KURO_PROMPT_GIT:=#97bedc}
: ${KURO_PROMPT_GIT_DIRTY:=#ffba7b}
: ${KURO_PROMPT_HOT:=#e27373}
: ${KURO_PROMPT_VENV:=#ffba7b}
: ${KURO_PROMPT_BOX:=#e27373}

setopt prompt_subst
autoload -Uz add-zsh-hook vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' check-for-staged-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{$KURO_PROMPT_GIT_DIRTY}●%F{$KURO_PROMPT_GIT}"
zstyle ':vcs_info:git:*' unstagedstr "%F{$KURO_PROMPT_GIT_DIRTY}*%F{$KURO_PROMPT_GIT}"
zstyle ':vcs_info:git:*' formats \
  " %F{$KURO_PROMPT_RULE}(%F{$KURO_PROMPT_GIT}%b%c%u%F{$KURO_PROMPT_RULE})%f"
zstyle ':vcs_info:git:*' actionformats \
  " %F{$KURO_PROMPT_RULE}(%F{$KURO_PROMPT_GIT}%b|%a%c%u%F{$KURO_PROMPT_RULE})%f"

# Adjust the rule width when a virtualenv label is shown, like af-magic does.
function afmagic_dashes() {
  local python_env_dir="${VIRTUAL_ENV:-$CONDA_DEFAULT_ENV}"
  local python_env="${python_env_dir##*/}"
  local width=${COLUMNS:-80}
  if [[ -n "$python_env" && "$RPROMPT" = *\(${python_env}\)* ]]; then
    (( width -= ${#python_env} + 3 ))
  elif [[ -n "$VIRTUAL_ENV_PROMPT" && "$RPROMPT" = *${VIRTUAL_ENV_PROMPT}* ]]; then
    (( width -= ${#VIRTUAL_ENV_PROMPT} + 3 ))
  fi
  (( width >= 20 )) || width=80
  print -n -- "$width"
}

function _kuro_af_precmd() {
  local last_status=$?
  vcs_info

  local venv="${VIRTUAL_ENV_PROMPT:-${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:t}}}"
  KURO_AF_VENV=""
  [[ -n "$venv" ]] && \
    KURO_AF_VENV=" %F{$KURO_PROMPT_RULE}[%F{$KURO_PROMPT_VENV}${venv}%F{$KURO_PROMPT_RULE}]%f"

  local box="" kind=""
  if [[ -n "${DISTROBOX_NAME:-}" ]]; then
    box="$DISTROBOX_NAME"; kind="distrobox"
  elif [[ -n "${CONTAINER_NAME:-}" || -n "${CONTAINER_ID:-}" ]]; then
    box="${CONTAINER_NAME:-${CONTAINER_ID[1,12]}}"; kind="container"
  elif [[ -f /.dockerenv ]]; then
    box="docker"; kind="container"
  elif [[ -f /run/.containerenv ]]; then
    box="podman"; kind="container"
  elif [[ -n "${container:-}" ]]; then
    box="$container"; kind="container"
  fi
  KURO_AF_BOX=""
  if [[ -n "${KURO_DYNASHELL:-}" ]]; then
    # dynashell exports this so the prompt shows a tag in the container slot.
    KURO_AF_BOX=" %F{$KURO_PROMPT_BOX}[imperative]%f"
  elif [[ -n "$box" ]]; then
    KURO_AF_BOX=" %F{$KURO_PROMPT_BOX}[${kind}:${box}]%f"
  fi

  KURO_AF_STATUS=""
  (( last_status != 0 )) && KURO_AF_STATUS=" %F{$KURO_PROMPT_HOT}${last_status} ↵%f"
}

add-zsh-hook precmd _kuro_af_precmd

PROMPT='%F{$KURO_PROMPT_RULE}${(l.$(afmagic_dashes)..-.)}%f
%F{$KURO_PROMPT_PATH}%~${vcs_info_msg_0_} %F{$KURO_PROMPT_GLYPH}%(!.#.»)%f '
RPROMPT='${KURO_AF_STATUS}${KURO_AF_VENV}${KURO_AF_BOX} %F{$KURO_PROMPT_RULE}%n@%m%f'
PS2='%F{$KURO_PROMPT_HOT}\ %f'
