return function()
    local defaultWorkspaceStyle = kuro and kuro.layout == "scrolling" and "slidevert" or "slide"
    hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })

    hl.animation({ leaf = "windows",          enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
    hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
    hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
    hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4, bezier = "easeOutQuint" })
    hl.animation({ leaf = "fade",             enabled = true, speed = 3, bezier = "easeOutQuint" })
    hl.animation({ leaf = "fadeIn",           enabled = true, speed = 3, bezier = "easeOutQuint" })
    hl.animation({ leaf = "fadeOut",          enabled = true, speed = 3, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layers",           enabled = true, speed = 3, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",         enabled = true, speed = 3, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersOut",        enabled = true, speed = 3, bezier = "easeOutQuint" })
    hl.animation({ leaf = "workspaces",       enabled = true, speed = 4, bezier = "easeOutQuint", style = defaultWorkspaceStyle })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = defaultWorkspaceStyle })
    local installedGestureMode = nil
    kuroSyncWorkspaceGestures = function(workspace, requestedMode)
        workspace = workspace or hl.get_active_special_workspace() or hl.get_active_workspace()
        local activeMode = requestedMode or (workspace and workspace.tiled_layout)
        local mode = activeMode == "scrolling" and "scrolling" or "dwindle"
        if workspace then
            local selector = workspace.special and tostring(workspace.name) or "name:" .. tostring(workspace.name)
            hl.workspace_rule({ workspace = selector, animation = mode == "scrolling" and "slidevert" or "slide" })
        end
        if mode == installedGestureMode then return end

        if installedGestureMode == "scrolling" then
            hl.gesture({ fingers = 3, direction = "horizontal", action = "unset" })
            hl.gesture({ fingers = 3, direction = "vertical", action = "unset" })
        elseif installedGestureMode == "dwindle" then
            hl.gesture({ fingers = 3, direction = "horizontal", action = "unset" })
        end

        if mode == "scrolling" then
            hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
            hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
        else
            hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
        end
        installedGestureMode = mode
    end

    kuroSyncWorkspaceGestures()
    hl.on("workspace.active", function(workspace)
        kuroSyncWorkspaceGestures(workspace)
    end)
end
