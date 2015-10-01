local wibox = require('wibox')
local l = require('layout')
local utility = require('utility')
local scheduler = require('scheduler')
local base = require('topjets.base')

-- Module topjets.kbd
local kbd = base()

local layouts = {[0] = "EN",
                 [1] = "UA",
                 [2] = "RU"}

function kbd.init()
   dbus.request_name("session", "ru.gentoo.kbdd")
   dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
   dbus.connect_signal("ru.gentoo.kbdd", function(_, layout) kbd.refresh_all(layout) end)
end

function kbd.new()
   local kbd_icon = wibox.widget.imagebox(base.icon("format-text-bold", 24))
   local kbd_text = wibox.widget.textbox(layouts[0])

   local _widget = l.fixed { l.margin { l.constrain { kbd_icon, size = vista.scale(24) },
                                        margin_right = vista.scale(4) },
                             kbd_text }
   _widget.kbd_text = kbd_text

   return _widget
end

function kbd.refresh(w, layout)
   w.kbd_text:set_markup(layouts[layout])
end

return kbd
