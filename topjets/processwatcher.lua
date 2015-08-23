local awful = require('awful')
local utility = require("utility")
local iconic = require('iconic')

local processwatcher = {
   ignore = { "defunct", "migration" },
   sorters = {
      { name = "CPU" , comp = function (a, b) return a.cpu > b.cpu end },
      { name = "Memory", comp = function (a, b) return a.mem > b.mem end } },
   font = "monospace 9",
   line_count = 10,
   default = { max_line_count = 100} }

local widget = nil
local cache = { data = nil, time = -1 }
local current_sorter = 1

function processwatcher.switch_sorter(dx)
   current_sorter = ((current_sorter + 1 + (dx or 1)) % #processwatcher.sorters) + 1
   if widget ~= nil then
      widget:emit_signal("mouse::leave")
      widget:emit_signal("mouse::enter")
   end
end

local function get_process_data()
   if os.time() - cache.time < 10 then
      return cache.data
   end

   local req = 'ps -eo pid,comm,pcpu,pmem'
   if #processwatcher.ignore > 0 then
      req = req .. ' | grep -v -E "' .. processwatcher.ignore[1]
      for i = 2, #processwatcher.ignore do
         req = req .. "|" .. processwatcher.ignore[i]
      end
      req = req .. '"'
   end

   local f = io.popen(req)
   f:read() -- Skip first line

   local processes = {}
   for l in f:lines() do
      local pid, pname, cpu, mem = l:match("([%d]+)%s+([^%s]+)%s+([%d%.]+%.[%d%.]+)%s+([%d%.]+%.[%d%.]+)")
      if processes[pname] == nil then
         processes[pname] = { cpu = 0, mem = 0, name = pname, pid = pid }
      end
      processes[pname].cpu = processes[pname].cpu + tonumber(cpu)
      processes[pname].mem = processes[pname].mem + tonumber(mem)
   end

   cache = { data = processes, time = os.time() }
   return processes
end

local function get_formatted_data()
   local sorter = processwatcher.sorters[current_sorter]
   local process_array = {}
   for _, v in pairs(get_process_data()) do
      table.insert(process_array, v)
   end

   table.sort(process_array, sorter.comp)

   local title = "Sorted by: " .. sorter.name
   local text = ""
   local pids = {}
   for i, p in ipairs(process_array) do
      if i > processwatcher.line_count then
         text = string.sub(text, 1, #text - 1)
         break
      end
      table.insert(pids, { name = p.name, pid = p.pid })
      text = text .. string.format("%s%s\n",
                                   utility.pop_spaces(p.name, string.format("%.1f", p.cpu), 19),
                                   utility.pop_spaces("", string.format("%.1f", p.mem), 6))
   end
   text = string.format('<span font="%s">%s</span>',
                        processwatcher.font, text)
   return { naughty = { title = title, text = text, timeout = 0,
                        icon = processwatcher.icon, icon_size = 48 },
            pids = pids }
end

local shown_pids = nil

function processwatcher.register(w, tooltip_position)
   widget = w
   processwatcher.icon = iconic.lookup_status_icon("indicator-cpufreq-00",
                                                   { preferred_size = "128x128" }),
   utility.add_hover_tooltip(
      w, function(w)
         local data = get_formatted_data()
         data.naughty.position = tooltip_position
         shown_pids = data.pids
         return data.naughty
   end)
end

local menu = nil

local function create_kill_menu()
   if shown_pids == nil then
      return
   end

   local items = {}
   for _, p in ipairs(shown_pids) do
      table.insert(items, { p.name, function()
                               awful.util.spawn("kill -9 " .. p.pid, false)
                               cache.time = -1
      end })
   end

   return awful.menu( { items = items, theme = { width = 150 } } )
end

function processwatcher.toggle_kill_menu()
   if menu then
      menu:hide()
      menu = nil
   else
      menu = create_kill_menu()
      if menu ~= nil then
         menu:toggle()
         if widget ~= nil then
            widget:emit_signal("mouse::leave")
         end
      end
   end
end

return processwatcher
