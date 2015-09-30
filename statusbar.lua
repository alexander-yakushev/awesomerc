local awful = require('awful')
local utility = require('utility')
local wibox = require('wibox')
local l = require('layout')
local topjets = require('topjets')
local beautiful = require('beautiful')
local awesompd = require('awesompd/awesompd')
local iconic = require('iconic')
local calendar = require('calendar')
local smartmenu = require('smartmenu')
local keymap = utility.keymap

local statusbar = { bars = {} }

local function map(f, coll)
   for i, v in ipairs(coll) do coll[i] = f(v) end
   return coll
end

local function terminal_with(command)
   return function() utility.spawn_in_terminal(command) end
end

function statusbar.create(s, options)
   options = options or { position = "right", width = 58 }
   local is_v = (options.position == "left") or (options.position == "right")
   options.is_vertical = is_v
   options.tooltip_position = (options.position == "left" and "bottom_left") or
      (options.position == "top" and "top_right") or "bottom_right"
   topjets.set_tooltip_position(options.tooltip_position)

   local bar = {}
   bar.wibox = awful.wibox { position = options.position, screen = s,
                             width = is_v and options.width or nil,
                             height = not is_v and options.width or nil}
   statusbar.initialize(bar, s, options)
   local w = bar.widgets

   local add_margin = function (_w) return l.margin { _w, margin = vista.scale(5) } end

   local layout = l.align {
      start = l.fixed { l.midpoint { l.margin { l.exact { w.menu_icon,
                                                          size = vista.scale(32) },
                                                margin = (options.width - vista.scale(32)) / 2 },
                                     vertical = is_v },
                        w.prompt,
                        vertical = is_v },
      middle = w.unitybar,
      finish = l.fixed (
         map(add_margin,
             { (is_v and
                   l.fixed { l.margin { w.weather, margin_bottom = vista.scale(5) },
                             l.margin { w.net, margin_top = vista.scale(5) },
                             vertical = true } or
                   l.flex { w.weather, w.net, vertical = true }),
                (is_v and
                    l.fixed { l.margin { w.kbd, margin_bottom = vista.scale(5) },
                              l.margin { w.cpu, margin_top = vista.scale(5) },
                              vertical = true } or
                    l.flex { w.kbd, w.cpu, vertical = true }),
                l.flex { w.vol,
                         w.mpd.widget,
                         vertical = not is_v },
                l.flex { w.mem,
                         w.battery,
                         vertical = not is_v },
                l.midpoint { w.time, vertical = is_v },
                vertical = is_v })),
      vertical = is_v }

   bar.wibox:set_widget(layout)
   statusbar.bars[s] = bar
   return bar.wibox
end

function statusbar.initialize(bar, s, options)
   local is_vertical = options.is_vertical
   local widgets = {}

   -- Menu
   widgets.menu_icon = awful.widget.button(
      { image = iconic.lookup_icon("start-here-arch3", { preferred_size = "128x128",
                                                         icon_types = { "/start-here/" }}) })
   widgets.menu_icon:buttons(keymap("LMB", smartmenu.show))

   -- Clock
   widgets.time = topjets.clock(options.width)
   calendar.register(widgets.time)
   widgets.time:buttons(
      keymap("LMB", function() awful.util.spawn(software.browser_cmd ..
                                                "calendar.google.com", false) end,
             "MMB", function() calendar.switch_month(0) end,
             "WHEELUP", function() calendar.switch_month(-1) end,
             "WHEELDOWN", function() calendar.switch_month(1) end))

   -- CPU widget
   widgets.cpu = topjets.cpu(is_vertical)
   topjets.processwatcher.register(widgets.cpu, options.tooltip_position)
   widgets.cpu:buttons(keymap("LMB", terminal_with("htop"),
                              "RMB", topjets.processwatcher.toggle_kill_menu,
                              "WHEELUP", function() topjets.processwatcher.switch_sorter(-1) end,
                              "WHEELDOWN", function() topjets.processwatcher.switch_sorter(1) end))

   -- Memory widget
   widgets.mem = topjets.memory()

   -- Battery widget
   widgets.battery = topjets.battery
   { { name = rc.laptop_name or "Laptop", primary = true,
       interval = 10, update_fn = topjets.battery.get_local },
      { name = "OnePlus One", addr = "192.168.1.142:5555",
        interval = 1800, update_fn = topjets.battery.get_via_adb,
        charge = "capacity", status = "status" },
   }
   widgets.battery:buttons(keymap("LMB", terminal_with("sudo powertop")))

   -- Network widget
   widgets.net = topjets.network(is_vertical)
   widgets.net:buttons(keymap("LMB", terminal_with("sudo wifi-menu")))

   -- Weather widget
   widgets.weather = topjets.weather(is_vertical)
   widgets.weather:buttons(keymap("LMB", widgets.weather.update))

   -- Volume widget
   widgets.vol = topjets.volume()
   widgets.vol:buttons(
      keymap("LMB", function() widgets.vol:mute() end,
             "WHEELUP", function() widgets.vol:inc() end,
             "WHEELDOWN", function() widgets.vol:dec() end))

   -- Keyboard widget
   widgets.kbd = topjets.kbd()

   -- MPD widget
   if s > 1 then
      -- MPD widget is one for all screens.
      widgets.mpd = statusbar.bars[1].widgets.mpd
   else
   local mpd = awesompd:create()
   awesompd.set_text = function(t) end
   mpd.widget_icon = iconic.lookup_icon("gmpc", { preferred_size = "24x24",
                                                  icon_types = { "/apps/" }})
   mpd.path_to_icons = beautiful.icon_dir
   mpd.browser = software.browser
   mpd.mpd_config = userdir .. "/.mpdconf"
   mpd.radio_covers = {
      ["listen.42fm.ru"] = "/home/unlogic/awesome/themes/devotion/stream_covers/42fm.jpg",
   }
   mpd:register_buttons({ { "", awesompd.MOUSE_LEFT, mpd:command_playpause() },
         { "Control", awesompd.MOUSE_SCROLL_UP, mpd:command_prev_track() },
         { "Control", awesompd.MOUSE_SCROLL_DOWN, mpd:command_next_track() },
         { "", awesompd.MOUSE_SCROLL_UP, mpd:command_volume_up() },
         { "", awesompd.MOUSE_SCROLL_DOWN, mpd:command_volume_down() },
         { "", awesompd.MOUSE_RIGHT, mpd:command_show_menu() },
         { "", "XF86AudioPlay", mpd:command_playpause() },
         { "", "XF86AudioStop", mpd:command_stop() },
         { "", "XF86AudioPrev", mpd:command_prev_track() },
         { "", "XF86AudioNext", mpd:command_next_track() }})
   mpd:run()
   mpd:init_onscreen_widget({ x = vista.scale(20), y = -vista.scale(30), font = "helvetica " .. vista.scale(11), screen = vista.primary })
   widgets.mpd = mpd
   end

   widgets.unitybar = topjets.unitybar { screen = s,
                                         width = options.width,
                                         horizontal = not is_vertical,
                                         thin = options.unitybar_thin_mode,
                                         fg_normal = "#888888",
                                         bg_urgent = "#ff000088" }

   widgets.prompt = awful.widget.prompt()

   bar.widgets = widgets
end

return setmetatable(statusbar, { __index = statusbar.bars })
