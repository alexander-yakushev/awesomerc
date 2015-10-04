local wibox = require('wibox')
local scheduler = require('scheduler')
local base = require('topjets.base')

-- Module topjets.cpu
local memory = base()

local icons = {}

function memory.init()
   for i, perc in ipairs({ "00", 20, 40, 60, 80, 100 }) do
      icons[i] = base.icon("brasero-disc-" .. perc, { 24, 128}, "actions")
   end
   scheduler.register_recurring("memory_update", 10, memory.update)
end

function memory.new()
   return wibox.widget.imagebox()
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

function memory.update()
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

   memory.data = _mem
   memory.data.icon = get_usage_icon(_mem.usep)

   memory.refresh_all(memory.data.icon[1])
end

function memory.refresh(w, icon)
   w:set_image(icon)
end

function memory.tooltip()
   local d = memory.data
   return { title = string.format("Usage:\t %d%%", d.usep),
            text = string.format("Used:\t %d MB\nFree:\t %d MB\nTotal:\t %d MB",
                                 d.inuse, d.free, d.total),
            icon = d.icon[2] }
end

return memory
