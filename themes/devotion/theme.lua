-- Serenity awesome theme
local util = require('awful.util')

theme = {}

local function res(res_name)
   return theme.theme_dir .. "/" .. res_name
end

theme.name = "Devotion 1.0"
theme.theme_dir = util.getdir("config") .. "/themes/devotion"

theme.wallpaper     = res("background.jpg")
theme.icon_dir      = res("icons")

theme.font          = "sans 9"

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

theme.bg_normal       = "#00000099"
theme.bg_focus        = "#00000033"

-- theme.motive          = "#82ee76" -- spring
theme.motive          = "#E67B50" -- summer
-- theme.motive          = "#dbaf5d" -- autumn
-- theme.motive          = "#76eec6" -- winter

theme.bg_normal_color = "#00000099"
theme.bg_focus_color  = "#444444"
theme.bg_urgent       = "#7f7f7f"
theme.bg_minimize     = "#444444"
theme.bg_onscreen     = theme.bg_normal

theme.fg_normal       = "#ffffff"
theme.fg_focus        = "#ffffff"
theme.fg_urgent       = "#ffffff"
theme.fg_minimize     = "#ffffff"
theme.fg_onscreen     = "#7f7f7f"

theme.taglist_bg_focus = res("taglist/bg_focus.png")

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

theme.icon_theme = "awoken"

-- Onscreen
local infojets = require("infojets")

local wb = infojets.create_wibox({ x = 20, y = 20, height = 200, width = 220, bg_color = theme.bg_normal })
local pw = infojets.processwatcher()
pw:set_process_sorters({ { name = "CPU", sort_by = "pcpu",
                           ignore = { "defunct", "migration" } },
                         { name = "Memory", sort_by = "rss",
                           ignore = { "defunct", "migration" } } })
pw.current_file = 2
pw.font = 'DejaVu Sans Mono 10'
pw.title_font = 'Helvetica 10'
pw.fg_focus = theme.motive
pw:calculate_line_count(200)
pw:run()

wb:set_widget(pw.widget)

return theme
