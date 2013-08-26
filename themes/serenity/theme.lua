-- Serenity awesome theme
local util = require('awful.util')

theme = {}

local function res(res_name)
   return theme.theme_dir .. "/" .. res_name
end

theme.name = "Serenity v0.1"
theme.theme_dir = util.getdir("config") .. "/themes/serenity"

theme.wallpaper     = res("background.jpg")
theme.icon_dir      = res("icons")

theme.font          = "sans 9"
theme.taglist_font  = "sans 10"

-- Menu settings
theme.menu_submenu_icon = res("icons/submenu.png")
theme.menu_height       = 15
theme.menu_width        = 110
theme.menu_border_width = 0

theme.bg_systray = "#222222"

theme.border_width    = 1
theme.border_normal   = "#222222"
theme.border_focus    = "#000000"
theme.border_marked   = "#91231c"

theme.bg_normal       = { type = "linear",
                          from = {0,0}, to = {0,21},
                          stops = { { 0, "#444444" }, { 1, "#121312" } } }
theme.bg_focus        = { type = "linear",
                          from = {0,0}, to = {0,21},
                          stops = { { 0, "#222222" }, { 1, "#646363" } } }

theme.motive          = "#76eec6"

theme.bg_normal_color = "#222222"
theme.bg_focus_color  = "#444444"
theme.bg_urgent       = "#7f7f7f"
theme.bg_minimize     = "#444444"
theme.bg_onscreen     = "#22222200"

theme.fg_normal       = "#dddddd"
theme.fg_focus        = "#ffffff"
theme.fg_urgent       = "#ffffff"
theme.fg_minimize     = "#ffffff"
theme.fg_onscreen     = "#7f7f7f"

-- Configure naughty
if naughty then
   local presets = naughty.config.presets
   presets.normal.bg = theme.bg_normal_color
   presets.normal.fg = theme.fg_normal_color
   presets.low.bg = theme.bg_normal_color
   presets.low.fg = theme.fg_normal_color
   presets.normal.border_color = theme.bg_focus_color
   presets.low.border_color = theme.bg_focus_color
   presets.critical.border_color = theme.motive
   presets.critical.bg = theme.bg_urgent
   presets.critical.fg = theme.motive
end

theme.onscreen_config = { processwatcher = { x = -20, y = 30 },
                          calendar = { text_color = theme.fg_normal,
                                       cal_x = 15, todo_x = 15,
                                       cal_y = 30, todo_y = 30 } }

theme.icon_theme = "awoken"

-- Onscreen widgets
local onscreen_file = theme.theme_dir .. "/onscreen.lua"

if util.file_readable(onscreen_file) then
   theme.onscreen = dofile(onscreen_file)
else
   error("E: beautiful: file not found: " .. onscreen_file)
end

return theme
