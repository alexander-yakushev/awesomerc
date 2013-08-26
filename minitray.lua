local wibox = require("wibox")

-- Module minitray
local minitray = {}

local function show()
   local geom = screen[mouse.screen].workarea
   minitray.wibox.height = 20
   minitray.wibox.width = minitray.tray.width or 100
   minitray.wibox:geometry({ x = geom.width - geom.x - minitray.wibox.width,
                             y = geom.y })
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

function minitray.toggle()
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
