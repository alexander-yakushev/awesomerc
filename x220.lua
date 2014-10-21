-- Standard awesome library
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
scheduler = require('scheduler')
private = require('private')
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Theme handling library
local beautiful = require('beautiful')
-- Notification library
naughty = require("naughty")
-- Logging library
log = require("log")
-- Quake console
local quake = require("quake")
-- Menubar
local menubar = require("menubar")
-- Utility
local utility = require("utility")
local currencies = require("currencies")
-- Dictionary
local dict = require("dict")
-- Thinkpad specific features
local thinkpad = require('thinkpad')

local minitray = require('minitray')
local statusbar = require('statusbar')

local picturesque = require('picturesque')

local lustrous = require('lustrous')
local smartmenu = require('smartmenu')

-- Map useful functions outside
calc = utility.calc
notify_at = utility.notify_at
money = currencies.recalc

userdir = utility.pslurp("echo $HOME", "*line")

-- Autorun programs
autorunApps = {
   "setxkbmap -layout 'us,ua,ru' -variant ',winkeys,winkeys' -option grp:menu_toggle -option compose:ralt -option terminate:ctrl_alt_bksp",
   'sleep 2; xmodmap ~/.xmodmap'
}

runOnceApps = {
   'thunderbird',
   'mpd',
   'xrdb -merge ~/.Xresources',
   'mpdscribble',
   'kbdd',
   '/usr/bin/avfsd -o allow_root -o intr -o sync_read /avfs',
   'owncloud',
   'pulseaudio --start',
   'redshift -l 60.8:10.7 -m vidmode -g 0.8 -t 6500:5000'
}

utility.autorun(autorunApps, runOnceApps)

-- Various initialization
thinkpad.touchpad.enable(false)

lustrous.init { lat = private.user.loc.lat,
                lon = private.user.loc.lon,
                offset = private.user.time_offset }

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/devotion/theme.lua")

-- {{{ Wallpaper
gears.wallpaper.maximized("/home/unlogic/Documents/Pictures/Wallpapers/umbrella.jpg", 1, true)
-- picturesque.sfw = true
-- scheduler.register_recurring("picturesque", 1800, picturesque.change_image)
-- }}}

-- Default system software
software = { terminal = "urxvt",
             terminal_cmd = "urxvt -e ",
             terminal_quake = "urxvt -pe tabbed",
             editor = "ec",
             editor_cmd = "ec ",
             browser = "firefox",
             browser_cmd = "firefox " }

-- Default modkey.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
   awful.layout.suit.floating, 	        -- 1
   awful.layout.suit.tile, 		-- 2
   awful.layout.suit.tile.bottom,	-- 3
   awful.layout.suit.max.fullscreen,
}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
do
   local f, t, b, fs = layouts[1], layouts[2], layouts[3], layouts[4]
   for s = 1, screen.count() do
      -- Each screen has its own tag table.
      tags[s] = awful.tag({ " 𝟏 ", " 𝟐 ", " 𝟑 ", " 𝟒 ", " 𝟓 ", " 𝟔 "}, s,
                          {  f ,  f ,  f ,  f ,  f ,  f })
   end
end
-- }}}

-- Right statusbar
for s = 1, screen.count() do
   statusbar.create(s)
end

-- Configure menubar
menubar.cache_entries = true
menubar.app_folders = { "/usr/share/applications/" }
menubar.show_categories = true

-- Interact with snap script

function snap ( filename )
   naughty.notify { title = "Screenshot captured: " .. filename:match ( ".+/(.+)" ),
                    text = "Left click to upload",
                    timeout = 10,
                    icon_size = 200,
                    icon = filename,
                    run = function (notif)
                       asyncshell.request ( "imgurbash " .. filename,
                                            function (f)
                                               local t = f:read()
                                               f:close()
                                               naughty.notify { title = "Image uploaded",
                                                                text = t,
                                                                run = function (notif)
                                                                   os.execute ( "echo " .. t .. " | xclip " )
                                                                   naughty.destroy(notif)
                                                                end }
                                            end )
                       naughty.destroy(notif)
                    end }
end

--- Smart Move a client to a screen. Default is next screen, cycling.
-- @param c The client to move.
-- @param s The screen number, default to current + 1.
function smart_movetoscreen(c, s)
   local was_maximized = { h = false, v = false }
   if c.maximized_horizontal then
      c.maximized_horizontal = false
      was_maximized.h = true
   end
   if c.maximized_vertical then
      c.maximized_vertical = false
      was_maximized.v = true
   end

   local sel = c or client.focus
   if sel then
      local sc = screen.count()
      if not s then
         s = sel.screen + 1
      end
      if s > sc then s = 1 elseif s < 1 then s = sc end
      sel.screen = s
      mouse.coords(screen[s].geometry)
   end

   if was_maximized.h then
      c.maximized_horizontal = true
   end
   if was_maximized.v then
      c.maximized_vertical = true
   end
end

-- {{{ Key bindings
globalkeys = awful.util.table.join(
   awful.key({                   }, "XF86Launch1", function() utility.spawn_in_terminal("ncmpc") end),
   awful.key({                   }, "Scroll_Lock", function() smartmenu.show() end),
   -- awful.key({                   }, "XF86TouchpadToggle", thinkpad.touchpad.toggle),
   awful.key({                   }, "XF86ScreenSaver", thinkpad.power.screenlock),
   awful.key({                   }, "XF86Battery", function() utility.spawn_in_terminal("sudo scripts/flashmanager") end),
   awful.key({                   }, "XF86Display", function() utility.spawn_in_terminal("scripts/switch-display") end),
   awful.key({                   }, "XF86AudioLowerVolume", function() statusbar.widgets.vol:dec() end),
   awful.key({                   }, "XF86AudioRaiseVolume", function() statusbar.widgets.vol:inc() end),
   awful.key({ modkey,           }, "l", minitray.toggle ),
   awful.key({ modkey,           }, "p", function() menubar.show() end ),
   awful.key({ modkey,           }, "e",   function()
                                              i = 3
                                              local screen = mouse.screen
                                              if tags[screen][i] then
                                                 awful.tag.viewonly(tags[screen][i])
                                              end
                                           end),
   awful.key({ modkey,           }, "d",   function()  utility.view_first_empty() end ),
   awful.key({ modkey,           }, "=",   dict.lookup_word),
   awful.key({ modkey,           }, "Left", function() utility.view_non_empty(-1) end),
   awful.key({ modkey,           }, "Right", function() utility.view_non_empty(1) end),
   awful.key({ modkey,           }, "Tab", awful.tag.history.restore),

   awful.key({ modkey,           }, "Up",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "Down",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end),
      awful.key({ modkey,           }, "j",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "k",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

   -- Layout manipulation
   awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
   awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
   awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
   awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
   awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
   awful.key({ modkey,           }, "i", function () awful.screen.focus_relative( 1) end),
   awful.key({ modkey,           }, "Tab",
             function ()
                awful.client.focus.history.previous()
                if client.focus then
                   client.focus:raise()
                end
             end),

   -- Standard program
   awful.key({ modkey,           }, "Return", function () quake.toggle({ terminal = software.terminal_quake,
                                                                         name = "URxvt",
                                                                         height = 0.5,
                                                                         skip_taskbar = true,
                                                                         ontop = true })
                                              end),

   awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
   awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
   awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
   awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
   awful.key({ modkey,           }, "space", function ()
                awful.layout.inc(layouts,  1)
                naughty.notify { title = "Layout changed",
                                 text = "Current layout: " .. awful.layout.get(mouse.screen).name,
                               }
                                             end),
   awful.key({ modkey, "Control" }, "n", awful.client.restore),
   awful.key({ }, "Print", function () awful.util.spawn("snap " .. os.date("%Y%m%d_%H%M%S")) end ),
   awful.key({ modkey }, "b", function ()
                                 statusbar.wiboxes[mouse.screen].visible = not statusbar.wiboxes[mouse.screen].visible
                                 local clients = client.get()
                                 local curtagclients = {}
                                 local tags = screen[mouse.screen]:tags()
                                 for _, c in ipairs(clients) do
                                    for k, t in ipairs(tags) do
                                       if t.selected then
                                          local ctags = c:tags()
                                          for _, v in ipairs(ctags) do
                                             if v == t then
                                                table.insert(curtagclients, c)
                                             end
                                          end
                                       end
                                    end
                                 end
                                 for _, c in ipairs(curtagclients) do
                                    if c.maximized_vertical then
                                       c.maximized_vertical = false
                                       c.maximized_vertical = true
                                    end
                                 end
                              end),
   -- Prompt
   awful.key({ modkey }, "r", function ()
                                 local promptbox = statusbar.widgets.prompt[mouse.screen]
                                 awful.prompt.run({ prompt = promptbox.prompt,
                                                    bg_cursor = beautiful.bg_focus_color },
                                                  promptbox.widget,
                                                  function (...)
                                                     local result = awful.util.spawn(...)
                                                     if type(result) == "string" then
                                                        promptbox.widget:set_text(result)
                                                     end
                                                  end,
                                                  awful.completion.shell,
                                                  awful.util.getdir("cache") .. "/history")
                              end),
   awful.key({ modkey }, "x", function ()
                                 awful.prompt.run({ prompt = "Run Lua code: ",
                                                    bg_cursor = beautiful.bg_focus_color },
                                                  statusbar.widgets.prompt[mouse.screen].widget,
                                                  awful.util.eval, nil,
                                                  awful.util.getdir("cache") .. "/history_eval")
                              end)
)

clientkeys = awful.util.table.join(
   awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
   awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
   awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
   awful.key({ modkey,           }, "o",      smart_movetoscreen                        ),
   awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
   awful.key({ modkey,           }, "n",
             function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
             end),
   awful.key({ modkey,           }, "m",
             function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
             end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
   globalkeys = awful.util.table.join(globalkeys,
                                      awful.key({ modkey }, "#" .. i + 9,
                                                function ()
                                                   local screen = mouse.screen
                                                   if tags[screen][i] then
                                                      awful.tag.viewonly(tags[screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Control" }, "#" .. i + 9,
                                                function ()
                                                   local screen = mouse.screen
                                                   if tags[screen][i] then
                                                      awful.tag.viewtoggle(tags[screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Shift" }, "#" .. i + 9,
                                                function ()
                                                   if client.focus and tags[client.focus.screen][i] then
                                                      awful.client.movetotag(tags[client.focus.screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                                                function ()
                                                   if client.focus and tags[client.focus.screen][i] then
                                                      awful.client.toggletag(tags[client.focus.screen][i])
                                                   end
                                                end))
end

clientbuttons = awful.util.table.join(
   awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
   awful.button({ modkey }, 1, awful.mouse.client.move),
   awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
statusbar.widgets.mpd:append_global_keys()
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
   -- All clients will match this rule.
   { rule = { },
     properties = { border_width = beautiful.border_width,
                    border_color = beautiful.border_normal,
                    size_hints_honor = false,
                    focus = true,
                    keys = clientkeys,
                    buttons = clientbuttons } },
   { rule = { class = "MPlayer" },
     properties = { floating = true } },
   { rule = { class = "Deluge" },
     properties = { tag = tags[screen.count() or 1][6] } },
   { rule = { class = "Transmission-gtk" },
     properties = { tag = tags[screen.count() or 1][6] } },
   { rule = { class = "Firefox" },
     properties = { tag = tags[screen.count() or 1][2] } },
   { rule = { class = "Chromium" },
     properties = { tag = tags[screen.count() or 1][2] } },
   { rule = { class = "Thunderbird" },
     properties = { tag = tags[screen.count() or 1][2] } },
   { rule = { class = "Pidgin" },
     properties = { tag = tags[screen.count() or 1][1],
                    floating = false} },
   { rule = { class = "Skype" },
     properties = { tag = tags[screen.count() or 1][1],
                    floating = true } },
   { rule = { class = "Viber" },
     properties = { tag = tags[screen.count() or 1][1],
                    floating = true } },
   { rule = { class = "Emacs" },
     properties = { tag = tags[screen.count() or 1][3] } },
   { rule = { class = "Steam" },
     properties = { tag = tags[screen.count() or 1][4] } },
   { rule = { class = "gimp" },
     properties = { floating = true,
                    tag = tags[screen.count() or 1][6]} },
   { rule = { class = "feh" },
     properties = { floating = true }},
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage",
                      function (c, startup)
                         -- Enable sloppy focus
                         c:connect_signal("mouse::enter",
                                          function(c)
                                             if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
                                                and awful.client.focus.filter(c) then
                                             client.focus = c
                                             end
                                          end)

                         if not startup then
                            -- Set the windows at the slave,
                            -- i.e. put it at the end of others instead of setting it master.
                            -- awful.client.setslave(c)

                            -- Put windows in a smart way, only if they does not set an initial position.
                            if not c.size_hints.user_position and not c.size_hints.program_position then
                               awful.placement.no_overlap(c)
                               awful.placement.no_offscreen(c)
                            end
                         end

                         local titlebars_enabled = false
                         if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
                            -- Widgets that are aligned to the left
                            local left_layout = wibox.layout.fixed.horizontal()
                            left_layout:add(awful.titlebar.widget.iconwidget(c))

                            -- Widgets that are aligned to the right
                            local right_layout = wibox.layout.fixed.horizontal()
                            right_layout:add(awful.titlebar.widget.floatingbutton(c))
                            right_layout:add(awful.titlebar.widget.maximizedbutton(c))
                            right_layout:add(awful.titlebar.widget.stickybutton(c))
                            right_layout:add(awful.titlebar.widget.ontopbutton(c))
                            right_layout:add(awful.titlebar.widget.closebutton(c))

                            -- The title goes in the middle
                            local title = awful.titlebar.widget.titlewidget(c)
                            title:buttons(awful.util.table.join(
                                             awful.button({ }, 1, function()
                                                             client.focus = c
                                                             c:raise()
                                                             awful.mouse.client.move(c)
                                                                  end),
                                             awful.button({ }, 3, function()
                                                             client.focus = c
                                                             c:raise()
                                                             awful.mouse.client.resize(c)
                                                                  end)
                                                               ))

                            -- Now bring it all together
                            local layout = wibox.layout.align.horizontal()
                            layout:set_left(left_layout)
                            layout:set_right(right_layout)
                            layout:set_middle(title)

                            awful.titlebar(c):set_widget(layout)
                         end
                      end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

scheduler.start()
-- }}}
