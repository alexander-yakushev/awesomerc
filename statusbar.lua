local awful = require('awful')
local utility = require('utility')
local wibox = require('wibox')
local topjets = require('topjets')
local beautiful = require('beautiful')
local awesompd = require('awesompd/awesompd')
local iconic = require('iconic')
local calendar = require('calendar')
local smartmenu = require('smartmenu')
local keymap = utility.keymap

local statusbar = { widgets = {}, wiboxes = {},
                    position = "right" }
local widgets = statusbar.widgets

local function constrain(widget, size)
   return wibox.layout.constraint(widget, 'exact', size, size)
end

local function terminal_with(command)
   return function() utility.spawn_in_terminal(command) end
end

function statusbar.create(s)
   if not statusbar.initialized then
      statusbar.initialize()
   end
   local w = widgets
   local I = widgets.separator

   local sound_and_music = wibox.layout.flex.horizontal()
   sound_and_music:add(w.vol)
   sound_and_music:add(w.mpd.widget)

   local mem_and_bat = wibox.layout.flex.horizontal()
   mem_and_bat:add(w.mem)
   mem_and_bat:add(w.battery)

   local ttime = wibox.layout.align.horizontal()
   ttime:set_middle(w.time)

   local cpu_and_net = wibox.layout.flex.horizontal()
   cpu_and_net:add(w.cpu)
   cpu_and_net:add(w.net)

   local menu_centered = wibox.layout.align.horizontal()
   menu_centered:set_middle(constrain(w.menu_icon, 32))

   local l = { top = { I, menu_centered, w.prompt[s], I },
               middle = w.unitybar[s],
               bottom = { w.weather,
                          w.net,
                          w.cpu,
                          sound_and_music,
                          mem_and_bat,
                          ttime
             } }

   local wb = awful.wibox { position = statusbar.position, screen = s, width = 58 }

   -- Widgets that are aligned to the top
   local top_layout = wibox.layout.fixed.vertical()
   for _, v in ipairs(l.top) do
      top_layout:add(v)
   end

   -- Widgets that are aligned to the bottom
   local bottom_layout = wibox.layout.fixed.vertical()
   for _, v in ipairs(l.bottom) do
      bottom_layout:add(wibox.layout.margin(v, 5, 5, 5, 5))
   end

   -- Now bring it all together (with the tasklist in the middle)
   local layout = wibox.layout.align.vertical()
   layout:set_top(top_layout)
   layout:set_middle(l.middle)
   layout:set_bottom(bottom_layout)

   wb:set_widget(layout)
   statusbar.wiboxes[s] = wb
   return wb
end

function statusbar.initialize()
   -- Menu
   widgets.menu_icon = awful.widget.button(
      { image = iconic.lookup_icon("start-here-arch3", { preferred_size = "128x128",
                                                         icon_types = { "/start-here/" }}) })
   widgets.menu_icon:buttons(keymap("LMB", smartmenu.show))

   widgets.separator = wibox.widget.textbox()
   widgets.separator:set_markup(" ")

   -- Clock widget
   widgets.time = wibox.widget.textbox()
   calendar.register(widgets.time)
   scheduler.register_recurring("topjets.clock", 30,
                                function()
                                   widgets.time:set_markup(os.date("%a %d\n %H:%M"))
   end)

   -- CPU widget
   widgets.cpu = topjets.cpu()
   topjets.processwatcher.register(widgets.cpu)
   widgets.cpu:buttons(keymap("LMB", terminal_with("htop"),
                              "RMB", topjets.processwatcher.toggle_kill_menu,
                              "WHEELUP", function() topjets.processwatcher.switch_sorter(-1) end,
                              "WHEELDOWN", function() topjets.processwatcher.switch_sorter(1) end))

   -- Memory widget
   widgets.mem = topjets.memory()

   -- Battery widget
   widgets.battery = topjets.battery({{ name = "ThinkPad X220", primary = true,
                                        interval = 10, update_fn = topjets.battery.get_local },
         { name = "OnePlus One", addr = "192.168.1.142:5555",
           interval = 1800, update_fn = topjets.battery.get_via_adb,
           charge = "capacity", status = "status" },
   })
   widgets.battery:buttons(keymap("LMB", terminal_with("sudo powertop")))

   -- Network widget
   widgets.net = topjets.network()
   widgets.net:buttons(keymap("LMB", terminal_with("sudo wifi-menu")))

   -- Weather widget
   widgets.weather = topjets.weather()
   widgets.weather:buttons(keymap("LMB", widgets.weather.update))

   -- Volume widget
   widgets.vol = topjets.volume()
   widgets.vol:buttons(
      keymap("LMB", function() widgets.vol:mute() end,
             "WHEELUP", function() widgets.vol:inc() end,
             "WHEELDOWN", function() widgets.vol:dec() end))

   -- MPD widget
   local mpd = awesompd:create()
   awesompd.STOPPED = ""
   mpd.backgroud = "#000000"
   mpd.widget_icon = iconic.lookup_icon("gmpc", { preferred_size = "24x24",
                                                  icon_types = { "/apps/" }})
   mpd.path_to_icons = beautiful.icon_dir
   mpd.browser = software.browser
   mpd.mpd_config = userdir .. "/.mpdconf"
   mpd.radio_covers = {
      ["listen.42fm.ru"] = "/home/unlogic/awesome/themes/devotion/stream_covers/42fm.jpg",
   }
   local f = io.popen("cd /home/unlogic/awesome/themes/devotion/stream_covers/di/; ls")
   for l in f:lines() do
      local t = l:match("(.+)%.png")
      if t ~= nil then
         mpd.radio_covers["di.fm:80/di_" .. t] = "/home/unlogic/awesome/themes/devotion/stream_covers/di/" .. t .. ".png"
      end
   end
   f:close()
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
   mpd:init_onscreen_widget({ x = 20, y = -30, font = "helvetica 11" })
   widgets.mpd = mpd

   widgets.unitybar = {}

   -- Native widgets
   widgets.prompt = {}

   for s = 1, screen.count() do
      widgets.prompt[s] = awful.widget.prompt()
      widgets.unitybar[s] = topjets.unitybar { screen = s,
                                               width = 58,
                                               fg_normal = "#888888",
                                               bg_urgent = "#ff000088",
                                               img_focused = beautiful.taglist_bg_focus }
   end

   statusbar.initialized = true
end

return statusbar
