local wibox = require('wibox')
local utility = require('utility')
local iconic = require('iconic')
local scheduler = require('scheduler')

-- Module topjets.kbd
local kbd = {}

local kbd_usage  = {}
local kbd_total  = {}
local kbd_active = {}

local layouts = {[0] = "EN",
                 [1] = "UA",
                 [2] = "RU"}

function kbd.new()
   local kbd_icon = wibox.widget.imagebox()
   local kbd_text = wibox.widget.textbox()

   local _widget = wibox.layout.fixed.horizontal()
   _widget:add (wibox.layout.constraint(kbd_icon, 'exact', 24, 24))
   _widget:add (kbd_text)

   kbd_icon:set_image(iconic.lookup_icon("preferences-desktop-locale", { preferred_size = "24x24" } ))
   kbd_text:set_markup(" " .. layouts[0])

   dbus.request_name("session", "ru.gentoo.kbdd")
   dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
   dbus.connect_signal("ru.gentoo.kbdd", function(...)
                          local data = {...}
                          local layout = data[2]
                          kbd_text:set_markup(" " .. layouts[layout])
                                         end)

   return _widget
end

return setmetatable(kbd, { __call = function(_, ...) return kbd.new(...) end})
