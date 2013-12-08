local awful = require('awful')
local utility = require('utility')
local wibox = require('wibox')
local topjets = require('topjets')
local beautiful = require('beautiful')
local awesompd = require('awesompd/awesompd')
local picturesque = require('picturesque')
local iconic = require('iconic')

local statusbar = { widgets = {}, wiboxes = {} }
local widgets = statusbar.widgets

local mouse = { LEFT = 1, MIDDLE = 2, RIGHT = 3, WHEEL_UP = 4, WHEEL_DOWN = 5 }

statusbar.position = "top"

local function keymap(...)
   local t = {}
   for _, k in ipairs({...}) do
      local but
      if type(k[1]) == "table" then
         but = awful.button(k[1], k[2], k[3])
      else
         but = awful.button({}, k[1], k[2])
      end
      t = awful.util.table.join(t, but)
   end
   return t
end

function statusbar.create(s)
   if not statusbar.initialized then
      statusbar.initialize()
   end
   local l
   local w = widgets
   local I = widgets.separator
   local O = widgets.separator2

   l = { left = { w.menu_icon, O, w.tags[s], O, w.prompt[s] },
         middle = w.programs[s],
         right = { O, w.mpd.widget, I, w.kbd, I, w.weather, I, w.net, I,
                   w.cpu, I, w.mem, I, w.vol, I, w.battery, I, w.time, O }
   }

   local wb = awful.wibox({ position = statusbar.position, screen = s , height = 22 })

   -- Widgets that are aligned to the left
   local left_layout = wibox.layout.fixed.horizontal()
   for _, v in ipairs(l.left) do
      left_layout:add(v)
   end

   -- Widgets that are aligned to the right
   local right_layout = wibox.layout.fixed.horizontal()
   for _, v in ipairs(l.right) do
      right_layout:add(v)
   end

   -- Now bring it all together (with the tasklist in the middle)
   local layout = wibox.layout.align.horizontal()
   layout:set_left(left_layout)
   layout:set_middle(l.middle)
   layout:set_right(right_layout)

   wb:set_widget(layout)
   statusbar.wiboxes[s] = wb
   return wb
end

function statusbar.initialize()
   -- Menu
   local mainmenu = { items = {
                         { 'awesome', { { "change wallpaper", picturesque.change_image },
                                        { "restart", awesome.restart },
                                        { "quit", awesome.quit } },
                           beautiful.awesome_icon},
                         { "connect to", { } } },
                      theme = { width = 150 } }

   widgets.menu_icon = awful.widget.launcher(
      { image = iconic.lookup_icon("start-here-arch3", { preferred_size = "24x24",
                                                         icon_types = { "/start-here/" }}),
        menu = awful.menu(mainmenu) })

   widgets.separator = wibox.widget.textbox()
   widgets.separator:set_markup("   ")

   widgets.separator2 = wibox.widget.textbox()
   widgets.separator2:set_markup(" ")

   -- Clock widget
   widgets.time = wibox.widget.textbox()
   scheduler.register_recurring("topjets.clock", 30,
                                function()
                                   widgets.time:set_markup(os.date("%a %d, %H:%M "))
                                end)

   -- CPU widget
   widgets.cpu = topjets.cpu()
   widgets.cpu:buttons(
      keymap({ mouse.LEFT, function() utility.spawn_in_terminal("htop") end }))

   -- Memory widget
   widgets.mem = topjets.memory()

   -- Battery widget
   widgets.battery = topjets.battery()

   -- Network widget
   widgets.net = topjets.network()

   -- Weather widget
   widgets.weather = topjets.weather()
   widgets.weather:buttons(
      keymap({ mouse.LEFT, widgets.weather.update}))

   -- Keyboard widget
   widgets.kbd = topjets.kbd()

   -- Volume widget
   widgets.vol = topjets.volume()
   widgets.vol:buttons(
      keymap({ mouse.LEFT, function() widgets.vol:mute() end },
             { mouse.WHEEL_UP, function() widgets.vol:inc() end },
             { mouse.WHEEL_DOWN, function() widgets.vol:dec() end }))

   -- MPD widget
   local mpd = awesompd:create()
   awesompd.STOPPED = ""
   mpd.font = "Liberation Mono"
   mpd.backgroud = "#000000"
   mpd.widget_icon = iconic.lookup_icon("gmpc", { preferred_size = "24x24",
                                                  icon_types = { "/apps/" }})
   mpd.scrolling = true
   mpd.output_size = 30
   mpd.update_interval = 10
   mpd.path_to_icons = beautiful.icon_dir
   mpd.debug_mode = true
   mpd.jamendo_format = awesompd.FORMAT_MP3
   mpd.show_album_cover = true
   mpd.browser = software.browser
   mpd.mpd_config = userdir .. "/.mpdconf"
   mpd.album_cover_size = 50
   mpd.ldecorator = " "
   mpd.rdecorator = ""
   mpd.servers = { { server = "localhost",
                     port = 6600 } }
   mpd:register_buttons({ { "", awesompd.MOUSE_LEFT, mpd:command_toggle() },
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
   widgets.mpd = mpd

   -- Native widgets
   widgets.prompt = {}
   widgets.layout = {}

   widgets.tags = {}
   widgets.tags.buttons = keymap({ mouse.LEFT, awful.tag.viewonly },
                                 { { modkey }, mouse.LEFT, awful.client.movetotag },
                                 { mouse.RIGHT, awful.tag.viewtoggle },
                                 { { modkey }, mouse.RIGHT, awful.client.toggletag },
                                 { mouse.WHEEL_UP, awful.tag.viewnext },
                                 { mouse.WHEEL_DOWN, awful.tag.viewprev })

   widgets.programs = {}
   statusbar.taskmenu = nil
   widgets.programs.buttons =
      keymap({ mouse.LEFT, function (c)
                  if not c:isvisible() then
                     awful.tag.viewonly(c:tags()[1])
                  end
                  client.focus = c
                  c:raise()
                           end },
                { mouse.RIGHT, function ()
                     if statusbar.taskmenu then
                        statusbar.taskmenu:hide()
                        statusbar.taskmenu = nil
                     else
                        statusbar.taskmenu = awful.menu.clients({ width=250 },
                                                                { callback = function()
                                                                     statusbar.taskmenu = nil
                                                                end})
                     end
                               end },
                { mouse.WHEEL_UP, function ()
                     awful.client.focus.byidx(1)
                     if client.focus then client.focus:raise() end
                                  end },
                { mouse.WHEEL_DOWN, function ()
                     awful.client.focus.byidx(-1)
                     if client.focus then client.focus:raise() end
                                    end })

      for s = 1, screen.count() do
         widgets.prompt[s] = awful.widget.prompt()

         widgets.layout[s] = awful.widget.layoutbox(s)
         widgets.layout[s]:buttons(
            keymap({ mouse.LEFT,       function () awful.layout.inc(layouts, 1) end },
                   { mouse.RIGHT,      function () awful.layout.inc(layouts, -1) end },
                   { mouse.WHEEL_UP,   function () awful.layout.inc(layouts, 1) end },
                   { mouse.WHEEL_DOWN, function () awful.layout.inc(layouts, -1) end }))

         local common = require("awful.widget.common")
         local function custom_update (w, buttons, label, data, objects)
            -- update the widgets, creating them if needed
            w:reset()
            for i, o in ipairs(objects) do
               local cache = data[o]
               local ib, tb, bgb, m, l
               if cache then
                  ib = cache.ib
                  tb = cache.tb
                  bgb = cache.bgb
                  m   = cache.m
               else
                  ib = wibox.widget.imagebox()
                  tb = wibox.widget.textbox()
                  bgb = wibox.widget.background()
                  m = wibox.layout.margin(tb, 4, 4)
                  l = wibox.layout.fixed.horizontal()

                  -- All of this is added in a fixed widget
                  l:fill_space(true)
                  l:add(ib)
                  l:add(m)

                  -- And all of this gets a background
                  bgb:set_widget(l)

                  bgb:buttons(common.create_buttons(buttons, o))

                  data[o] = {
                     ib = ib,
                     tb = tb,
                     bgb = bgb,
                     m   = m
                  }
               end

               local text, bg, bg_image, icon = label(o)
               -- The text might be invalid, so use pcall
               text = string.format('<span color="#%s">%s</span>',
                                    (#o:clients() == 0 and "444444" or "cccccc"),
                                    text)
               if not pcall(tb.set_markup, tb, text) then
                  tb:set_markup("<i>&lt;Invalid text&gt;</i>")
               end
               bgb:set_bg(bg)
               w:add(bgb)
            end
         end
         widgets.tags[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, widgets.tags.buttons, nil, custom_update)

         widgets.programs[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, widgets.programs.buttons)

         statusbar.initialized = true
      end
end

return statusbar
