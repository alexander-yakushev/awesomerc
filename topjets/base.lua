local iconic = require('iconic')
local utility = require('utility')
local vista = require('vista')

-- Basis for all topjets widgets
local base = { tooltip_position = "bottom_right",
               tooltip_icon_size_dpi = 48 }

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
                                      if tt.icon_size == nil then
                                         tt.icon_size = vista.scale(base.tooltip_icon_size_dpi)
                                      end
                                      if tt.timeout == nil then
                                         tt.timeout = 0
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

function base.icon(name, category)
   local args = {}
   if category ~= nil then
      args.icon_types = { "/" .. category .. "/" }
   end
   result = {}

   local small_size = "24x24"
   if vista.scale(1, true) > 1.1 then
      -- For HiDPI screens small icons are also 128px wide.
      small_size = "128x128"
   end

   args.preferred_size = small_size
   result.small = iconic.lookup_icon(name, args)

   args.preferred_size = "128x128"
   result.large = iconic.lookup_icon(name, args)

   return result
end

function base.notify(opts)
   opts.position = opts.position or base._tooltip_position
   opts.icon_size = opts.icon_size or vista.scale(base.tooltip_icon_size_dpi)
   opts.screen = opts.screen or mouse.screen
   return naughty.notify(opts)
end

return setmetatable(base, { __call = function(_, ...) return base.define(...) end})
