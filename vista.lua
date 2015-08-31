-- Module for querying, managing and configuring screens.
local vista = { primary = 1, secondary = 1, properties = {} }

local function merge(src, dst)
   for k, v in pairs(src) do
      dst[k] = v
   end
end

local function screen_name(scr)
   local name
   for k, v in pairs(scr.outputs) do
      name = k
      break
   end
   return name
end

local function matches(s, rule)
   local scr = screen[s]
   local geom = scr.geometry
   local w, h = geom.width, geom.height
   local ratio = w / h
   for k, v in pairs(rule) do
      if k == "name" then
         local name = screen_name(scr)
         if name ~= v then
            return false
         end
      end
      if k == "ratio" then
         local ratio_exp, quant = string.match(tostring(v), "([%d%.]+)(.?)")
         ratio_exp = tonumber(ratio_exp)
         if (quant == "+" and ratio < ratio_exp) or
            (quant == "-" and ratio > ratio_exp) or
            (quant ==  "" and ratio ~= ratio_exp) then
               return false
         end
      end
   end
   return true
end

function vista.setup(rules)
   for s = 1, screen.count() do
      vista.properties[s] = {}
   end
   for i = #rules, 1, -1 do
      for s = 1, screen.count() do
         if matches(s, rules[i].rule) then
            local p = rules[i].properties
            if p.primary then
               vista.primary = s
            end
            if p.secondary then
               vista.secondary = s
            end
            p.primary = nil
            p.secondary = nil
            merge(p, vista.properties[s])
         end
      end
   end
end

local function next_screen()
   local s = mouse.screen + 1
   if s > screen.count() then
      s = 1
   end
   return s
end

--- Jump cursor to the center of the screen. Default is next screen, cycling.
function vista.jump_cursor(s)
   local geom = screen[s or next_screen()].geometry
   mouse.coords { x = geom.x + (geom.width / 2),
                  y = geom.y + (geom.height / 2) }
end

--- Smart Move a client to a screen. Default is next screen, cycling.
-- @param c The client to move.
-- @param s The screen number, default to current + 1.
function vista.movetoscreen(c, s)
   c = c or client.focus
   local was_maximized = { h = false, v = false }
   if c.maximized_horizontal then
      c.maximized_horizontal = false
      was_maximized.h = true
   end
   if c.maximized_vertical then
      c.maximized_vertical = false
      was_maximized.v = true
   end

   if c then
      s = s or next_screen()
      c.screen = s
      vista.jump_cursor(s)
   end

   if was_maximized.h then
      c.maximized_horizontal = true
   end
   if was_maximized.v then
      c.maximized_vertical = true
   end
end

return setmetatable(vista, { __index = vista.properties })
