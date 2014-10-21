-- Infojets widget library
-- Version 0.4.0
-- Alex Yakushev <yakushev.alex@gmail.com>
-- Licensed under WTFPLv2.

local wibox = require("wibox")
local theme = require("beautiful")

local infojets = {
   -- logwatcher = require("infojets.logwatcher"),
   processwatcher = require("infojets.processwatcher"),
   -- jetclock = require("infojets.jetclock"),
   util = require("infojets.util")
}

local wiboxes = {}

function infojets.create_wibox(args)
   local args = args or {}
   local width = args.width or 300
   local height = args.height or 200
   local bg_color = args.bg_color or theme.bg_normal or "#000000"
   local ontop = (args.ontop ~= nil) and args.ontop or false
   local visible = (args.visible ~= nil) and args.visible or true

   local wbox = wibox({ bg = bg_color,
                        height = height,
                        width = width})
   wbox.ontop = ontop
   wbox.visible = visible
   infojets.reposition_wibox(wbox, args)

   wiboxes[wbox] = args
   return wbox
end

function infojets.reposition_wibox(wbox, args)
   if not args then
      args = wiboxes[wbox]
   end

   local scr = args.screen or 1
   local scrgeom = screen[scr].geometry --workarea
   local width = wbox.width
   local height = wbox.height
   local x = args.x or 0
   local y = args.y or 0

   if x >= 0 then
      x = scrgeom.x + x
   else
      x = scrgeom.x + scrgeom.width + x - width
   end

   if y >= 0 then
      y = scrgeom.y + y
   else
      y = scrgeom.y + scrgeom.height + y - height
   end

   wbox:geometry({ x = x, y = y})
end

return infojets
