pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// GPU activity from PCI runtime power state, NVIDIA SMI, or DRM busy counters.
Singleton {
    id: root

    property bool available: false
    property string name: ""
    property int utilization: 0
    property string runtimeStatus: "unknown"
    property bool pendingNvidiaQuery: false
    readonly property bool running: (available && (utilization > 0 || runtimeStatus === "active")) || Capture.recording
    readonly property string summary: Capture.recording
        ? "GPU active · screen recording"
        : !available ? "GPU activity unavailable"
        : name + " · " + (running ? "running" : "idle")
          + (runtimeStatus !== "unknown" ? " · runtime " + runtimeStatus : "")
          + " · " + utilization + "%"

    function refresh(queryNvidia) {
        if (proc.running) {
            if (queryNvidia === true) pendingNvidiaQuery = true;
            return;
        }
        proc.command = ["sh", "-c", root.script, "sh", queryNvidia === true ? "1" : "0"];
        proc.running = true;
    }

    readonly property string script: [
        'runtime=unknown; gpu_name=""',
        'for d in /sys/bus/pci/devices/*; do',
        '  [ -r "$d/class" ] || continue',
        '  class=$(cat "$d/class" 2>/dev/null)',
        '  driver=$(basename "$(readlink "$d/driver" 2>/dev/null)")',
        '  case "$class:$driver" in 0x03*:*|*:amdgpu|*:nvidia|*:nouveau|*:i915|*:xe) ;; *) continue;; esac',
        '  state=$(cat "$d/power/runtime_status" 2>/dev/null)',
        '  case "$state" in active) runtime=active;; suspended) [ "$runtime" = active ] || runtime=suspended;; esac',
        '  [ -n "$gpu_name" ] || gpu_name=${driver:-GPU}',
        'done',
        'if [ "${1:-0}" = 1 ] && command -v nvidia-smi >/dev/null 2>&1; then',
        '  n=$(nvidia-smi --query-gpu=name,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk -F, \'NF >= 2 {name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); value=$2+0; if (best == "" || value > max) {max=value; best=name}} END {if (NR) printf "%s|%d\\n", best, max}\')',
        '  if [ -n "$n" ]; then printf "%s|%s\\n" "$n" "$runtime"; exit 0; fi',
        'fi',
        'max=0; best=""',
        'for d in /sys/class/drm/card[0-9]*/device; do',
        '  driver=$(basename "$(readlink "$d/driver" 2>/dev/null)")',
        '  for f in "$d/gpu_busy_percent" "$d"/gt/gt*/gt_busy_percent; do',
        '    [ -r "$f" ] || continue',
        '    value=$(cat "$f" 2>/dev/null)',
        '    case "$value" in ""|*[!0-9]*) continue;; esac',
        '    if [ -z "$best" ] || [ "$value" -gt "$max" ]; then max=$value; best=${driver:-GPU}; fi',
        '  done',
        'done',
        'if [ -n "$best" ]; then printf "%s|%s|%s\\n" "$best" "$max" "$runtime"; exit 0; fi',
        'if [ "$runtime" != unknown ]; then printf "%s|0|%s\\n" "${gpu_name:-GPU}" "$runtime"; else echo unavailable; fi'
    ].join("\n")

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("|");
                root.available = fields.length >= 3 && fields[0] !== "";
                root.name = root.available ? fields[0] : "";
                root.utilization = root.available
                    ? Math.max(0, Math.min(100, parseInt(fields[1]) || 0)) : 0;
                root.runtimeStatus = root.available ? fields[2] : "unknown";
            }
        }
        onExited: {
            if (!root.pendingNvidiaQuery) return;
            root.pendingNvidiaQuery = false;
            Qt.callLater(() => root.refresh(true));
        }
    }

    Component.onCompleted: refresh(false)
}
