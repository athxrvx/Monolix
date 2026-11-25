#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SNAPSHOT_DIR = Path.home() / ".local/share/hypr-snapshots"
SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)

IGNORED_CLASSES = {
    "quickshell",
    "waybar",
    "ags",
    "eww",
    "swaync",
    "dunst",
    "mako",
    "rofi",
    "wofi",
    "fuzzel",
    "anyrun",
    "walker",
    "swww",
    "hyprpaper",
    "wl-clipboard",
    "xwaylandvideobridge",
}

PROMPT_QML_CODE = """
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        implicitWidth: 360
        implicitHeight: 96
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:snapshot-prompt"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#1e1e2e"
            border.color: "#89b4fa"
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    text: "Snapshot Name"
                    color: "#cdd6f4"
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: "#11111b"
                    border.color: input.activeFocus ? "#89b4fa" : "#313244"
                    border.width: 1

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        selectByMouse: true
                        focus: true

                        Component.onCompleted: forceActiveFocus()

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "e.g. coding, work, default..."
                            color: "#585b70"
                            font.pixelSize: 14
                            visible: !input.text && !input.activeFocus
                        }

                        onAccepted: {
                            const name = text.trim() || "default";
                            console.log("SNAP_NAME:" + name);
                            Qt.quit();
                        }

                        Keys.onEscapePressed: Qt.quit()
                    }
                }
            }
        }
    }
}
"""


def hyprctl(cmd: list[str], is_json: bool = True):
    full_cmd = ["hyprctl"] + (["-j"] if is_json else []) + cmd
    res = subprocess.run(full_cmd, capture_output=True, text=True, check=True)
    return json.loads(res.stdout) if is_json else res.stdout.strip()


def is_ignored_window(client: dict) -> bool:
    win_class = client.get("class", "").lower()
    init_class = client.get("initialClass", "").lower()
    if not win_class and not init_class:
        return True
    return any(
        ignored in win_class or ignored in init_class
        for ignored in IGNORED_CLASSES
    )


def get_process_cmd_and_cwd(pid: int) -> tuple[list[str], str | None]:
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            args = [arg.decode("utf-8", errors="replace") for arg in f.read().split(b"\0") if arg]
        cwd = os.readlink(f"/proc/{pid}/cwd")
        return args, cwd
    except (FileNotFoundError, PermissionError, ProcessLookupError):
        return [], None


def ask_snapshot_name() -> str | None:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".qml", delete=True) as tmp:
        tmp.write(PROMPT_QML_CODE)
        tmp.flush()

        res = subprocess.run(
            ["quickshell", "--no-duplicate", "-p", tmp.name],
            capture_output=True,
            text=True,
        )

    output = f"{res.stdout}\n{res.stderr}"
    for line in output.splitlines():
        if "SNAP_NAME:" in line:
            return line.split("SNAP_NAME:", 1)[-1].strip()
    return None


def save_snapshot(name: str):
    ws = hyprctl(["activeworkspace"])
    ws_id = ws["id"]
    ws_layout = ws.get("tiledLayout", "dwindle")

    clients = hyprctl(["clients"])
    ws_clients = [
        c for c in clients
        if c["workspace"]["id"] == ws_id
        and c["mapped"]
        and not is_ignored_window(c)
    ]

    ws_clients.sort(key=lambda c: (c["at"][1], c["at"][0]))

    saved_windows = []
    for c in ws_clients:
        cmd, cwd = get_process_cmd_and_cwd(c["pid"])
        if not cmd:
            continue
        saved_windows.append({
            "class": c["class"],
            "title": c["title"],
            "cmd": cmd,
            "cwd": cwd,
            "at": c["at"],
            "size": c["size"],
            "floating": c["floating"],
            "fullscreen": c["fullscreen"],
            "pinned": c["pinned"],
        })

    snapshot = {
        "workspace_id": ws_id,
        "layout": ws_layout,
        "windows": saved_windows,
    }

    out_file = SNAPSHOT_DIR / f"{name}.json"
    out_file.write_text(json.dumps(snapshot, indent=2))
    print(f"Saved {len(saved_windows)} windows (layout: {ws_layout}) to {out_file}")


def restore_snapshot(name: str):
    in_file = SNAPSHOT_DIR / f"{name}.json"
    if not in_file.exists():
        sys.exit(f"Snapshot '{name}' not found at {in_file}")

    snapshot = json.loads(in_file.read_text())
    ws = hyprctl(["activeworkspace"])
    ws_id = ws["id"]

    layout = snapshot.get("layout")
    if layout:
        hyprctl(["keyword", "workspace", f"{ws_id}, layout:{layout}"], is_json=False)

    spawned = []

    for win in snapshot["windows"]:
        existing_addrs = {c["address"] for c in hyprctl(["clients"])}

        cwd = win["cwd"] if win["cwd"] and os.path.isdir(win["cwd"]) else None
        subprocess.Popen(
            win["cmd"],
            cwd=cwd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

        new_addr = None
        for _ in range(50):
            time.sleep(0.1)
            for c in hyprctl(["clients"]):
                if c["address"] not in existing_addrs and c["mapped"] and not is_ignored_window(c):
                    new_addr = c["address"]
                    break
            if new_addr:
                break

        if not new_addr:
            print(f"Warning: timed out waiting for {win['class']}")
            continue

        state_cmd = "setfloating" if win["floating"] else "settiled"
        batch = [
            f"dispatch movetoworkspacesilent {ws_id},address:{new_addr}",
            f"dispatch {state_cmd} address:{new_addr}",
        ]
        hyprctl(["--batch", "; ".join(batch)], is_json=False)
        spawned.append((new_addr, win))

    time.sleep(0.15)
    current_clients = {c["address"]: c for c in hyprctl(["clients"])}

    for addr, win in spawned:
        curr = current_clients.get(addr)
        if not curr:
            continue

        target_x, target_y = win["at"]
        target_w, target_h = win["size"]

        if win["floating"]:
            batch = [
                f"dispatch resizewindowpixel exact {target_w} {target_h},address:{addr}",
                f"dispatch movewindowpixel exact {target_x} {target_y},address:{addr}",
            ]
            hyprctl(["--batch", "; ".join(batch)], is_json=False)
        else:
            dw = target_w - curr["size"][0]
            dh = target_h - curr["size"][1]
            if abs(dw) > 5 or abs(dh) > 5:
                hyprctl(["dispatch", "resizewindowpixel", f"{dw} {dh},address:{addr}"], is_json=False)
                current_clients = {c["address"]: c for c in hyprctl(["clients"])}

        if win.get("pinned"):
            hyprctl(["dispatch", "pin", f"address:{addr}"], is_json=False)

        if win.get("fullscreen", 0) > 0:
            hyprctl(["dispatch", "focuswindow", f"address:{addr}"], is_json=False)
            hyprctl(["dispatch", "fullscreen", str(win["fullscreen"])], is_json=False)

    print(f"Restored snapshot '{name}' onto workspace {ws_id}")


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in ("save", "restore"):
        sys.exit("Usage: hypr-snapshot [save|restore] [snapshot_name]")

    action = sys.argv[1]
    given_name = sys.argv[2].strip() if len(sys.argv) > 2 else ""
    snap_name = given_name if given_name else ask_snapshot_name()

    if not snap_name:
        sys.exit(0)

    if action == "save":
        save_snapshot(snap_name)
    else:
        restore_snapshot(snap_name)

