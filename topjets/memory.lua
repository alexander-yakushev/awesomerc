local utility = require('utility')
local wibox = require('wibox')
local iconic = require('iconic')
local scheduler = require('scheduler')

-- Module topjets.cpu
local memory = {}

local icons = {}
local icon_files = { "brasero-disc-00", "brasero-disc-20", "brasero-disc-40",
                     "brasero-disc-60", "brasero-disc-80", "brasero-disc-100" }

function memory.new()
   for i, f in ipairs(icon_files) do
      icons[i] = { small = iconic.lookup_icon(f, { preferred_size = "24x24",
                                                   icon_types = { "/actions/" }}),
                   large = iconic.lookup_icon(f, { preferred_size = "128x128",
                                                   icon_types = { "/actions/" }}) }
   end

   local _widget = wibox.widget.imagebox()
   scheduler.register_recurring("memory_update", 10,
                                function() memory.update(_widget) end)
   utility.add_hover_tooltip(_widget,
                             function(w)
                                local f = string.format
                                return { title = f("Usage:\t %d%%", w.data.usep),
                                         text = f("Used:\t %d MB\nFree:\t %d MB\nTotal:\t %d MB",
                                                  w.data.inuse, w.data.free, w.data.total),
                                         icon = w.data.icon.large, icon_size = 48,
                                         timeout = 0 }
                             end)
   return _widget
end

local function get_usage_icon (usage_p)
   if usage_p > 100 then
      usage_p = 100
   end
   if usage_p < 0 then
      usage_p = 0
   end
   local idx = math.floor ( ( usage_p + 10 ) / 20 ) + 1
   return icons[idx]
end

function memory.update(w)
   local _mem = { buf = {} }

   -- Get MEM info
   for line in io.lines("/proc/meminfo") do
      for k, v in string.gmatch(line, "([%a]+):[%s]+([%d]+).+") do
         if     k == "MemTotal"  then _mem.total = math.floor(v/1024)
         elseif k == "MemFree"   then _mem.buf.f = math.floor(v/1024)
         elseif k == "Buffers"   then _mem.buf.b = math.floor(v/1024)
         elseif k == "Cached"    then _mem.buf.c = math.floor(v/1024)
         end
      end
   end

   -- Calculate memory percentage
   _mem.free  = _mem.buf.f + _mem.buf.b + _mem.buf.c
   _mem.inuse = _mem.total - _mem.free
   _mem.usep  = math.floor(_mem.inuse / _mem.total * 100)

   w.data = _mem
   w.data.icon = get_usage_icon(_mem.usep)

   w:set_image(w.data.icon.small)
end

return setmetatable(memory, { __call = function(_, ...) return memory.new(...) end})
