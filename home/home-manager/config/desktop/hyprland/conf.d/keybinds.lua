return function(apps)
    local mod = "SUPER" -- Physical Alt key after kuro's xkb swap.
    -- local home = os.getenv("HOME") or ""   -- only used by the disabled Flea binding
    local barLayout = apps.barLayout

    local function setWorkspaceLayout(layout)
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not workspace then return end

        local selector = workspace.special
            and tostring(workspace.name)
            or "name:" .. tostring(workspace.name)
        hl.workspace_rule({
            workspace = selector,
            layout = layout,
            animation = layout == "scrolling" and "slidevert" or "slide",
        })
        if kuroSyncWorkspaceGestures then kuroSyncWorkspaceGestures(workspace, layout) end
    end

    local function cycleWorkspaceLayout()
        local layouts = { "dwindle", "scrolling" }
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not workspace then return end

        local nextLayout = layouts[1]
        for i, layout in ipairs(layouts) do
            if layout == workspace.tiled_layout then
                nextLayout = layouts[(i % #layouts) + 1]
                break
            end
        end
        setWorkspaceLayout(nextLayout)
    end

    hl.bind(mod .. "+ S",                  hl.dsp.window.pin())
    hl.bind(mod .. " + Q",                 hl.dsp.window.close())
    hl.bind("ALT + Q",                     hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + Return",    hl.dsp.exec_cmd(apps.terminal))
    hl.bind(mod .. " + A",                 hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))
    hl.bind(mod .. " + V",                 hl.dsp.exec_cmd("qs -c shell ipc call launcher enter sys-clipboard"))
    hl.bind(mod .. " + N",                 hl.dsp.exec_cmd("qs -c shell ipc call notifications toggle"))
    hl.bind(mod .. " + SHIFT + Escape",    hl.dsp.exec_cmd("qs -c shell ipc call lock lock"))
    hl.bind(mod .. " + B",                 hl.dsp.exec_cmd("qs -c shell ipc call sidebar toggle"))
    hl.bind(mod .. " + SHIFT + B",         hl.dsp.exec_cmd(barLayout .. " next"))
    hl.bind(mod .. " + M",                 hl.dsp.exec_cmd("hyprctl dispatch exit"))
    -- Flea is disabled; use the file manager from kuro.toml for SUPER + F.
    -- local fleaToggle = home .. "/.config/hypr/scripts/toggle-filemanager.sh"
    -- hl.bind(mod .. " + F",                 hl.dsp.exec_cmd(fleaToggle))
    -- hl.bind("ALT + F",                     hl.dsp.exec_cmd(fleaToggle))
    hl.bind(mod .. " + F",                 hl.dsp.exec_cmd("thunar"))
    hl.bind(mod .. " + W",                 hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + R",                 hl.dsp.exec_cmd(apps.menu))
    hl.bind(mod .. " + space",             hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))
    hl.bind(mod .. " + SHIFT + P",         hl.dsp.window.pseudo())
    hl.bind(mod .. " + SHIFT + S",         hl.dsp.layout("togglesplit"))
    hl.bind(mod .. " + SHIFT + Space", cycleWorkspaceLayout)
    hl.bind(mod .. " + O", function() setWorkspaceLayout("dwindle") end)
    hl.bind(mod .. " + P", function() setWorkspaceLayout("scrolling") end)
    hl.bind("Print",                      hl.dsp.exec_cmd("qs -c shell ipc call capture toggle"))

    -- Focus with Alt+arrows or Alt+HJKL.
    hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "l" }))
    hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
    hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "u" }))
    hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "d" }))
    hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "l" }))
    hl.bind(mod .. " + L",     hl.dsp.focus({ direction = "r" }))
    hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "u" }))
    hl.bind(mod .. " + J",     hl.dsp.focus({ direction = "d" }))

    -- Move the active window with Alt+Shift+arrows or Alt+Shift+HJKL.
    hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + H",     hl.dsp.window.move({ direction = "l" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + L",     hl.dsp.window.move({ direction = "r" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + K",     hl.dsp.window.move({ direction = "u" }), { repeating = true })
    hl.bind(mod .. " + SHIFT + J",     hl.dsp.window.move({ direction = "d" }), { repeating = true })

    -- Resize the active window with Alt+Ctrl+arrows or Alt+Ctrl+HJKL.
    hl.bind(mod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + H",     hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + L",     hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + K",     hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + J",     hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

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
