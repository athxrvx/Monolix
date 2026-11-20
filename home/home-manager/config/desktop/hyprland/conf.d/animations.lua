return function()
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
    hl.animation({ leaf = "workspaces",       enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })

    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
end
