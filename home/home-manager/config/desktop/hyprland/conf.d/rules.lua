return function()
    hl.layer_rule({
        name  = "quickshell-overview",
        match = { namespace = "^quickshell-overview$" },
        blur  = true,
        ignore_alpha = 0.0,
    })

    hl.layer_rule({
        name  = "quickshell-notifications",
        match = { namespace = "^quickshell-notifications$" },
        blur  = true,
        ignore_alpha = 0.0,
    })

    hl.window_rule({
        name = "pip-sticky",
        match = {
            title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$",
        },
        float = true,
        pin = true,
        keep_aspect_ratio = true,
        size = { 480, 270 },
        move = { "monitor_w-window_w-20", "monitor_h-window_h-20" },
    })

    hl.window_rule({
        name   = "launcher-tui",
        match  = { class = "^omarchy-launcher-tui$" },
        float  = true,
        center = true,
        size   = { 900, 620 },
    })

    hl.window_rule({
        name   = "scratch",
        match  = { class = "^scratch$" },
        float  = true,
        center = true,
        size   = { 1300, 900 },
    })
    -- Flea is disabled; its popup rule is kept here for reference.
    -- hl.window_rule({
    --     name   = "flea-file-manager-popup",
    --     match  = { class = "^com\\.thisisgm\\.flea$" },
    --     float  = true,
    --     center = true,
    --     workspace = "special:filemanager",
    --     size   = { 1100, 720 },
    -- })

    hl.window_rule({
        name  = "fix-xwayland-drags",
        match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
        no_focus = true,
    })
end
