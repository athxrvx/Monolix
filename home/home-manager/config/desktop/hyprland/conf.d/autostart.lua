return function(home)
    hl.on("hyprland.start", function()
        hl.exec_cmd("awww-daemon")
        -- Quickshell owns org.freedesktop.Notifications. Stop any older
        -- notification daemon first so it cannot claim the D-Bus name.
        hl.exec_cmd("pkill -x swaync 2>/dev/null || true; pkill -x mako 2>/dev/null || true; pkill -x dunst 2>/dev/null || true; quickshell -p " .. home .. "/.config/quickshell/shell")
        hl.exec_cmd("wl-paste --type text  --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)
end
