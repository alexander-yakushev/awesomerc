local wibox = require('wibox')
local l = require('layout')
local utility = require('utility')
local scheduler = require('scheduler')
local base = require('topjets.base')
local util = require('awful.util')

-- Module topjets.cpu
local cpu = base()

local icons = {}

function cpu.init()
   for i, perc in ipairs({ "00", 25, 50, 75, 100 }) do
      icons[i] = base.icon("indicator-cpufreq-" .. perc, "status")
   end

   scheduler.register_recurring("cpu_update", 5, cpu.update)
end

function cpu.new(is_vertical)
   local cpu_icon = wibox.widget.imagebox()
   local cpu_text = wibox.widget.textbox()

   local _widget = l.fixed { l.margin { l.constrain { cpu_icon, size = vista.scale(24) },
                                        margin_right = vista.scale(4) },
                             cpu_text }

   _widget.cpu_icon = cpu_icon
   _widget.cpu_text = cpu_text
   _widget.is_vertical = is_vertical

   return _widget
end

local function get_usage_icon (usage_p)
   if usage_p > 100 then
      usage_p = 100
   end
   if usage_p < 0 then
      usage_p = 0
   end
   local idx = math.floor ( ( usage_p + 12.5 ) / 25 ) + 1
   return icons[idx]
end

function cpu.update()
   local cpu_lines = {}
   local cpu_usage  = {}
   local cpu_total  = {}
   local cpu_active = {}

   -- Get CPU stats
   local f = io.open("/proc/stat")
   for line in f:lines() do
      if string.sub(line, 1, 3) ~= "cpu" then break end

      cpu_lines[#cpu_lines+1] = {}

      for i in string.gmatch(line, "[%s]+([^%s]+)") do
         table.insert(cpu_lines[#cpu_lines], i)
      end
   end
   f:close()

   -- Ensure tables are initialized correctly
   for i = #cpu_total + 1, #cpu_lines do
      cpu_total[i]  = 0
      cpu_usage[i]  = 0
      cpu_active[i] = 0
   end

   for i, v in ipairs(cpu_lines) do
      -- Calculate totals
      local total_new = 0
      for j = 1, #v do
         total_new = total_new + v[j]
      end
      local active_new = total_new - (v[4] + v[5])

      -- Calculate percentage
      local diff_total  = total_new - cpu_total[i]
      local diff_active = active_new - cpu_active[i]

      if diff_total == 0 then diff_total = 1E-6 end
      cpu_usage[i]      = math.floor((diff_active / diff_total) * 100)

      -- Store totals
      cpu_total[i]   = total_new
      cpu_active[i]  = active_new
   end

   local temp = 0
   for i = 0, 5 do -- reasonable maximum
      local file = "/sys/class/thermal/thermal_zone" .. i .. "/temp"
      if util.file_readable(file) then
         local new_temp = utility.slurp(file, "*line")
         temp = math.max(temp, math.floor(tonumber(new_temp) / 1000))
      else
         break
      end
   end

   cpu.refresh_all(temp, get_usage_icon(cpu_usage[1]))
end

function cpu.refresh(w, temp, icon)
   local line = string.format("%d%s°C", temp, w.is_vertical and "\n" or "")
   w.cpu_text:set_markup(line)
   w.cpu_icon:set_image(icon.small)
end

return cpu
