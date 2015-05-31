-- Standard awesome library
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local menubar = require("menubar")
naughty = require("naughty")
log = require("log")
scheduler = require('scheduler')
private = require('private')
require("awful.autofocus")
local beautiful = require('beautiful')

local quake = require("quake")
local utility = require("utility")
local currencies = require("currencies")
local dict = require("dict")
local thinkpad = require('thinkpad')
local minitray = require('minitray')
local statusbar = require('statusbar')
local lustrous = require('lustrous')
local smartmenu = require('smartmenu')
local rulez = require('rulez')

-- Map useful functions outside
calc = utility.calc
notify_at = utility.notify_at
money = currencies.recalc
conv = utility.conversion

userdir = utility.pslurp("echo $HOME", "*line")

-- Autorun programs
autorunApps = {
   "setxkbmap -layout 'us,ua,ru' -variant ',winkeys,winkeys' -option grp:menu_toggle -option compose:ralt -option terminate:ctrl_alt_bksp",
   'sleep 2; xmodmap ~/.xmodmap'
}

runOnceApps = {
   'hexchat',
   'mpd',
   'xrdb -merge ~/.Xresources',
   'mpdscribble',
   'kbdd',
   '/usr/bin/avfsd -o allow_root -o intr -o sync_read /avfs',
   'owncloud',
   'pulseaudio --start',
   'redshift -l 60.8:10.7 -m vidmode -t 6500:5000',
   'workrave &!',
}

utility.autorun(autorunApps, runOnceApps)

-- Various initialization
lustrous.init(private.user.loc)

-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/devotion/theme.lua")

-- Wallpaper
gears.wallpaper.maximized(beautiful.wallpaper, 1, true)

-- Default system software
software = { terminal = "urxvt",
             terminal_cmd = "urxvt -e ",
             terminal_quake = "urxvt",
             editor = "ec",
             editor_cmd = "ec ",
             browser = "chromium",
             browser_cmd = "chromium " }

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
   awful.layout.suit.floating,
   awful.layout.suit.tile,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.max.fullscreen,
}

-- Tags
tags = {}
do
   local f, t, b, fs = layouts[1], layouts[2], layouts[3], layouts[4]
   for s = 1, screen.count() do
      tags[s] = awful.tag(
         { " 𝟏 ", " 𝟐 ", " 𝟑 ", " 𝟒 ", " 𝟓 ", " 𝟔 "}, s,
         {   f ,    f ,    f ,    f ,    f ,    f })
   end
end

-- Statusbar
for s = 1, screen.count() do
   statusbar.create(s)
end

-- Configure menubar
menubar.cache_entries = true
menubar.app_folders = { "/usr/share/applications/" }
menubar.show_categories = true

-- Interact with snap script
function snap(filename)
   naughty.notify { title = "Screenshot captured: " .. filename:match(".+/(.+)"),
                    text = "Left click to upload",
                    timeout = 10,
                    icon_size = 200,
                    icon = filename,
                    run = function(notif)
                       asyncshell.request("imgurbash " .. filename,
                                          function(f)
                                             local t = utility.slurp(f, "*line")
                                             os.execute("echo " .. t .. " | xclip")
                                             naughty.notify { title = "Image uploaded",
                                                              text = t }
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

-- Key bindings
globalkeys = utility.keymap(
   -- Tag/client navigation
   "M-Left", function() utility.view_non_empty(-1) end,
   "M-Right", function() utility.view_non_empty(1) end,
   "M-Tab", awful.tag.history.restore,
   "M-Up", function() awful.client.focus.byidx(1) utility.refocus() end,
   "M-Down", function() awful.client.focus.byidx(-1) utility.refocus() end,
   "M-j", function() awful.client.focus.byidx(1) utility.refocus() end,
   "M-k", function() awful.client.focus.byidx(-1) utility.refocus() end,
   "M-d", function() utility.view_first_empty() end,
   "M-u", awful.client.urgent.jumpto,
   "M-Tab", function() awful.client.focus.history.previous() utility.refocus() end,
   "M-C-n", awful.client.restore,
   -- Application launching
   "XF86Launch1", function() utility.spawn_in_terminal("ncmpc") end,
   "Scroll_Lock", smartmenu.show,
   "M-p", function() menubar.show() end,
   "M-=", dict.lookup_word,
   "Print", function() awful.util.spawn("snap " .. os.date("%Y%m%d_%H%M%S")) end,
   "M-Return", function ()
      quake.toggle({ terminal = software.terminal_quake,
                     name = "URxvt",
                     height = 0.5,
                     skip_taskbar = true,
                     ontop = true })
               end,
   "M-r", function ()
      local promptbox = statusbar.widgets.prompt[mouse.screen]
      awful.prompt.run({ prompt = promptbox.prompt },
         promptbox.widget,
         function (...)
            local result = awful.util.spawn(...)
            if type(result) == "string" then
               promptbox.widget:set_text(result)
            end
         end,
         awful.completion.shell,
         awful.util.getdir("cache") .. "/history")
          end,
   "M-x", function ()
      awful.prompt.run({ prompt = "Run Lua code: " },
         statusbar.widgets.prompt[mouse.screen].widget,
         awful.util.eval, nil,
         awful.util.getdir("cache") .. "/history_eval")
          end,
   -- Miscellaneous
   "XF86ScreenSaver", thinkpad.power.screenlock,
   "XF86AudioLowerVolume", function() statusbar.widgets.vol:dec() end,
   "XF86AudioRaiseVolume", function() statusbar.widgets.vol:inc() end,
   "M-l", minitray.toggle,
   "M-space", function()
      awful.layout.inc(layouts, 1)
      naughty.notify { title = "Layout changed", timeout = 2,
                       text = "Current layout: " .. awful.layout.get(mouse.screen).name }
              end,
   "M-b", function()
      statusbar.wiboxes[mouse.screen].visible = not statusbar.wiboxes[mouse.screen].visible
          end
)

clientkeys = utility.keymap(
   "M-f", function (c) c.fullscreen = not c.fullscreen end,
   "M-S-c", function (c) c:kill() end,
   "M-C-space", awful.client.floating.toggle,
   "M-o", smart_movetoscreen,
   "M-q", rulez.remember,
   "M-t", function (c) c.ontop = not c.ontop end,
   "M-n", function (c) c.minimized = true end,
   "M-m", function (c)
      c.maximized_horizontal = not c.maximized_horizontal
      c.maximized_vertical   = not c.maximized_vertical
          end
)

-- Compute the maximum number of digit we need, limited to 9
local keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
for i = 1, keynumber do
   globalkeys = utility.keymap(
      globalkeys,
      "M-#" .. i + 9, function ()
         local screen = mouse.screen
         if tags[screen][i] then
            awful.tag.viewonly(tags[screen][i])
         end
                      end,
      "M-C-#" .. i + 9, function ()
         local screen = mouse.screen
         if tags[screen][i] then
            awful.tag.viewtoggle(tags[screen][i])
         end
                        end,
      "M-S-#" .. i + 9, function ()
         if client.focus and tags[client.focus.screen][i] then
            awful.client.movetotag(tags[client.focus.screen][i])
         end
                        end
   )
end

clientbuttons = utility.keymap(
   "LMB", function (c) client.focus = c; c:raise() end,
   "M-LMB", awful.mouse.client.move,
   "M-RMB", awful.mouse.client.resize)

statusbar.widgets.mpd:append_global_keys()
root.keys(globalkeys)

-- Rules
rulez.init({ { rule = { },
               properties = { border_width = beautiful.border_width,
                              border_color = beautiful.border_normal,
                              size_hints_honor = false,
                              focus = true,
                              keys = clientkeys,
                              buttons = clientbuttons } } })

-- Signals
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
                            -- Put windows in a smart way, only if they does not set an initial position.
                            if not c.size_hints.user_position and not c.size_hints.program_position then
                               awful.placement.no_overlap(c)
                               awful.placement.no_offscreen(c)
                            end
                         end
end)

scheduler.start()
