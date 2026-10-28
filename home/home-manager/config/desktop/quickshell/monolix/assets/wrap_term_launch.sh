#!/usr/bin/env sh

state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
cat "$state_home/quickshell/user/generated/terminal/sequences.txt" 2>/dev/null

exec "$@"
