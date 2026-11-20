return function(apps)
    local mod = "SUPER" -- Physical Alt key after kuro's xkb swap.
    -- local home = os.getenv("HOME") or ""   -- only used by the disabled Flea binding
    local barLayout = apps.barLayout

    hl.bind(mod .. " + Q",                 hl.dsp.window.close())
    hl.bind("ALT + Q",                     hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + Return",    hl.dsp.exec_cmd(apps.terminal))
    hl.bind(mod .. " + A",                 hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))
    hl.bind(mod .. " + V",                 hl.dsp.exec_cmd("qs -c shell ipc call launcher enter sys-clipboard"))
    hl.bind(mod .. " + TAB",               hl.dsp.exec_cmd("qs -c shell ipc call overview toggle"))
    hl.bind(mod .. " + N",                 hl.dsp.exec_cmd("qs -c shell ipc call notifications toggle"))
    hl.bind(mod .. " + L",                 hl.dsp.exec_cmd("qs -c shell ipc call lock lock"))
    hl.bind(mod .. " + B",                 hl.dsp.exec_cmd("qs -c shell ipc call sidebar toggle"))
    hl.bind(mod .. " + SHIFT + B",         hl.dsp.exec_cmd(barLayout .. " next"))
    hl.bind(mod .. " + M",                 hl.dsp.exec_cmd("hyprctl dispatch exit"))
    -- Flea is disabled; use the file manager from kuro.toml for SUPER + F.
    -- local fleaToggle = home .. "/.config/hypr/scripts/toggle-filemanager.sh"
    -- hl.bind(mod .. " + F",                 hl.dsp.exec_cmd(fleaToggle))
    -- hl.bind("ALT + F",                     hl.dsp.exec_cmd(fleaToggle))
    hl.bind(mod .. " + F",                 hl.dsp.exec_cmd("nautilus"))
    hl.bind(mod .. " + W",                 hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + R",                 hl.dsp.exec_cmd(apps.menu))
    hl.bind(mod .. " + space",             hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))
    hl.bind(mod .. " + P",                 hl.dsp.window.pseudo())
    hl.bind(mod .. " + J",                 hl.dsp.layout("togglesplit"))
    hl.bind(mod .. " + SHIFT + space",     hl.dsp.exec_cmd("sh -c 'layout=$(hyprctl -j getoption general:layout | jq -r .str); if [ \"$layout\" = master ]; then hyprctl keyword general:layout dwindle; else hyprctl keyword general:layout master; fi'"))
    hl.bind("Print",                      hl.dsp.exec_cmd("qs -c shell ipc call capture toggle"))

    hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

    for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
end
