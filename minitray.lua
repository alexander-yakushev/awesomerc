-- Toggable tray, for those who don't like to see it all the time.
-- http://awesome.naquadah.org/wiki/Minitray
-- Usage: after requiring a module, bind minitray.toggle() to a key.

local wibox = require("wibox")

-- Module minitray
local minitray = { geometry = {} }

local function show()
   local scrgeom = screen[mouse.screen].workarea
   minitray.wibox.height = minitray.geometry.height or 20
   local items = awesome.systray()
   if items == 0 then items = 1 end
   minitray.wibox.width = minitray.geometry.width or (minitray.wibox.height * items)
   minitray.wibox:geometry({ x = minitray.geometry.x or (scrgeom.width - scrgeom.x - minitray.wibox.width),
                             y = minitray.geometry.y or scrgeom.y })
   minitray.wibox.visible = true
end

local function init()
   minitray.wibox = wibox({})
   minitray.wibox.ontop = true
   minitray.layout = wibox.layout.align.horizontal()
   minitray.tray = wibox.widget.systray()
   minitray.layout:set_right(minitray.tray)
   minitray.wibox:set_widget(minitray.layout)
end

local function hide()
   minitray.wibox.visible = false
end

function minitray.toggle(geometry)
   if geometry then
      minitray.geometry = geometry
   end

   if not minitray.wibox then
      init()
   end

   if minitray.wibox.visible then
      hide()
   else
      show()
   end
end

return minitray
