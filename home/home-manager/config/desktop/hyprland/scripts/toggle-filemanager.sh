#!/usr/bin/env bash
# Disabled: Flea is not part of this flake. SUPER + F now launches the file
# manager configured in ~/.config/kuro/kuro.toml (Nautilus by default).
#
# app_class="com.thisisgm.flea"
# active=$(hyprctl activewindow -j | jq -r '.class // ""')
# if [ "$active" = "$app_class" ]; then
#     hyprctl dispatch togglespecialworkspace filemanager
#     exit
# fi
# hyprctl dispatch moveactiveworkspace special:filemanager
# cd "$HOME" || exit 1
# exec ./flea --gui
