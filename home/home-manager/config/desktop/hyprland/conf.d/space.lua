
-- ~/.config/hypr/conf.d/space.lua
return function()
    -- Load the Hyprspace plugin from the NixOS system profile
    local plugin_path = "/run/current-system/sw/lib/libHyprspace.so"
    local f = io.open(plugin_path, "r")
    if f then
        f:close()
        hl.dispatch(hl.dsp.exec_cmd("hyprctl plugin load " .. plugin_path))
    end

    -- Configure Hyprspace directly from kuro.colors (loaded in hyprland.lua)
    hl.config({
        plugin = {
            overview = {
                panelColor                = kuro.colors.base,
                panelBorderColor          = kuro.colors.accent,
                workspaceActiveBackground = kuro.colors.base,
                workspaceActiveBorder     = kuro.colors.accent,
                workspaceInactiveBorder   = kuro.colors.ink,
                panelBorderWidth          = 3,
                onBottom                  = false,
                autoDrag                  = true,
            },
        },
    })

    -- Keybindings
    hl.bind("SUPER + TAB", function()
        hl.plugin.overview.toggle()
    end, { description = "Toggle Hyprspace overview on current monitor" })

    hl.bind("SUPER + SHIFT + TAB", function()
        hl.plugin.overview.toggle("all")
    end, { description = "Toggle Hyprspace overview on all monitors" })
end
