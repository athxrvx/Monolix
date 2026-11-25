-- Hyprland entry point. Settings are grouped in conf.d; Kuro owns appearance
-- and input values generated from ~/.config/kuro/kuro.toml.
local home = os.getenv("HOME") or ""
local configDir = home .. "/.config/hypr"
local modulesDir = configDir .. "/conf.d"

-- Load generated colors, app choices, appearance and input options first.
pcall(require, "kuro")

local apps = {
    terminal = (kuro and kuro.apps and kuro.apps.terminal) or "kitty",
    fileManager = (kuro and kuro.apps and kuro.apps.fileManager) or "dolphin",
    menu = (kuro and kuro.apps and kuro.apps.menu) or "qs -c shell ipc call launcher toggle",
    barLayout = home .. "/.local/bin/bar-layout",
}

local function loadModule(name, ...)
    local configure = dofile(modulesDir .. "/" .. name .. ".lua")
    configure(...)
end

-- Apply categories in a deliberate order: outputs, environment, visual
-- behavior, startup, rules, then interactive bindings.
loadModule("monitor")
loadModule("environment", apps.terminal)
loadModule("layouts")
loadModule("animations")
loadModule("space")
loadModule("autostart", home)
loadModule("rules")
loadModule("keybinds", apps)
loadModule("media")
