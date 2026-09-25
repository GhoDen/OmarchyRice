-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")
o.bind("SUPER + Q", "Quit Application", hl.dsp.window.close())
o.bind("SUPER + E", "File Manager", { tui = "yazi", focus = true })
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + C", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + H", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + K", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))


-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Toggle Window Float", hl.dsp.window.float({ action = "toggle" }))

hl.unbind("SUPER + F")
o.bind("SUPER + F", "Tiled Full Screen", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Full Screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "1Password Quick Access Menu", "1password --quick-access")

hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Keybindings", "omarchy-menu-keybindings")

hl.unbind("SUPER + K")
o.bind("SUPER + K", "Focus on left window", hl.dsp.focus({ direction = "l" }))

hl.unbind("SUPER + J")
o.bind("SUPER + J", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + T")
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
hl.unbind("SUPER + ALT + F")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

