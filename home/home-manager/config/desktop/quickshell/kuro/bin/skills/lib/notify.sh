#!/usr/bin/env bash
# Shared desktop-notification helpers for the Kuro AI skills.
# Source from a skill with:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/notify.sh"

notify() {
    local urgency=${1:-normal} summary=$2 body=$3
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name=Kuro --urgency="$urgency" "$summary" "$body" 2>/dev/null || true
}

notify_ok() { notify normal "$1" "$2"; }
notify_error() { notify critical "$1" "$2"; }
