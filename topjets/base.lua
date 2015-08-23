local iconic = require('iconic')
local utility = require('utility')

-- Basis for all topjets widgets
local base = { tooltip_position = "bottom_right" }

local function constructor(wdg_class)
   return function (...)
      if not wdg_class._initialized then
         wdg_class.init(...)
         wdg_class._initialized = true
      end
      local wdg = wdg_class.new(...)
      if wdg_class.tooltip then
         wdg._tooltip_position = base.tooltip_position
         utility.add_hover_tooltip(wdg, function(...)
                                      local tt = wdg_class.tooltip()
                                      if tt.position == nil then
                                         tt.position = wdg._tooltip_position
                                      end
                                      return tt
         end)
      end
      table.insert(wdg_class._widgets, wdg)
      return wdg
   end
end

local function refresher(wdg_class)
   return function (...)
      for _, w in ipairs(wdg_class._widgets) do
         wdg_class.refresh(w, ...)
      end
   end
end

function base.define(t)
   local new_class = t or {}
   new_class._widgets = {}
   new_class.make = constructor(new_class)
   new_class.refresh_all = refresher(new_class)
   return setmetatable(new_class, { __call = function(_, ...)
                                       return new_class.make(...)
                      end })
end

function base.icon(name, sizes, category)
   local args = {}
   if category ~= nil then
      args.icon_types = { "/" .. category .. "/" }
   end
   if type(sizes) == "table" then
      local result = {}
      for i, size in ipairs(sizes) do
         args.preferred_size = size .. "x" .. size
         result[i] = iconic.lookup_icon(name, args)
      end
      return result
   else
      args.preferred_size = sizes .. "x" .. sizes
      return iconic.lookup_icon(name, args)
   end
end

return setmetatable(base, { __call = function(_, ...) return base.define(...) end})
