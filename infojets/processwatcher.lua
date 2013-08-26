local naughty = require('naughty')
local string = string
local ipairs = ipairs
local awful = require('awful')
local setmetatable = setmetatable
local table = table
local io = io
local os = os
local type = type
local math = math
local tonumber = tonumber
local join = awful.util.table.join
local wibox = require("wibox")
local theme = require("beautiful")
local util = require("infojets.util")
local terminal = terminal or "xterm"
local pango = util.pango
local log = require("gears.debug")
local tostring = tostring
local scheduler = scheduler

module("infojets.processwatcher")

default = {}
default.max_line_count = 100

local menu = nil

function set_process_sorters(w, sorters)
   for _, s in ipairs(sorters) do
      local req = 'ps -eo pid,comm,pcpu,pmem --sort ' .. s.sort_by
      table.insert(w.source_files, { name = s.name,
                                     request = req,
                                     ignore = s.ignore })
   end
end

function init_widgets(w)
   local ui = {}
   local title_bar = wibox.layout.flex.horizontal()
   ui.title_bar = {}

   local mouse_wheel = join(awful.button({ }, 4,
                                         function()
                                            local file = w:current_filedata()
                                            file.shift = file.shift - w.scroll_step
                                            if file.shift < 0 then
                                               file.shift = 0
                                            end
                                            w:refresh()
                                         end),
                            awful.button({ }, 5,
                                         function()
                                            local file = w:current_filedata()
                                            file.shift = file.shift + w.scroll_step
                                            if file.shift + w.line_count > #file.lines then
                                               file.shift = math.max(#file.lines - w.line_count, 0)
                                            end
                                            w:refresh()
                                         end),
                            awful.button({ }, 2,
                                         function()
                                            local file = w:current_filedata()
                                            file.shift = 0
                                            w:refresh()
                                         end))

   local menu_click = awful.button({ }, 1, function()
                                              if menu then
                                                 menu:hide()
                                                 menu = nil
                                              else
                                                 menu = w:create_kill_menu()
                                                 menu:toggle()
                                              end
                                           end)

   local right_click = awful.button({ }, 3, function()
                                               w:show_in_terminal()
                                            end)

   for i, v in ipairs(w.source_files) do
      local tbox = wibox.widget.textbox()
      local mouse_click = awful.button({ }, 1, function()
                                                  w.current_file = i
                                                  local to_data = w:current_filedata()
                                                  to_data.shift = 0
                                                  w:refresh()
                                               end)
      tbox:buttons(join(mouse_click, mouse_wheel))
      table.insert(ui.title_bar, tbox)
      title_bar:add(tbox)
   end

   local log_textbox = wibox.widget.textbox()
   log_textbox:buttons(join(mouse_wheel, right_click, menu_click))
   log_textbox:set_valign("top")
   log_textbox:set_align("right")
   ui.log_textbox = log_textbox

   local altogether = wibox.layout.align.vertical()
   altogether:set_first(title_bar)
   altogether:set_second(log_textbox)
   w.ui = ui
   w.widget = altogether
end

function new()
   w = {}
   w.source_files = {}
   w.data = {}
   w.max_line_count = default.max_line_count
   w.current_file = default.current_file or 1
   w.line_count = 5
   w.font = 'sans 8'
   w.title_font = 'sans 8'
   w.scroll_step = 2
   w.line_length = 30
   w.fg_normal = theme.fg_normal
   w.fg_focus = theme.motive

   w.set_process_sorters = set_process_sorters
   w.run = run
   w.update = update
   w.get_last_lines = get_last_lines
   w.init_widgets = init_widgets
   w.get_result_string = get_result_string
   w.refresh = refresh
   w.calculate_line_count = calculate_line_count
   w.show_in_terminal = show_in_terminal
   w.current_filedata = current_filedata
   w.create_kill_menu = create_kill_menu
   return w
end

function run(w)
   for i, f in ipairs(w.source_files) do
      w.data[f.name] = { lines = {}, shift = 0,
                         mask = f.mask,
                         request = f.request,
                         ignore = f.ignore }
   end

   w:init_widgets()

   scheduler.register_recurring("processwatcher_update", 10,
                                function()
                                   for _, f in ipairs(w.source_files) do
                                      w:update(f.name)
                                   end
                                end)
   -- util.repeat_every(, 10)
end

function trasform_line(line, mask)
   local parts = { string.find(line, mask) }
   local result = ""
   for i = 3, #parts do
      result = result .. parts[i]
   end
   return result
end

function current_filedata(w)
   return w.data[w.source_files[w.current_file].name]
end

function update(w, file)
   local filedata = w.data[file]
   local request = filedata.request .. ' | tail -' .. w.max_line_count .. ' | tac'

   if filedata.ignore then
      request = request .. ' | grep -v -E "' .. filedata.ignore[1]
      for i = 2, #filedata.ignore do
         request = request .. "|" .. filedata.ignore[i]
      end
      request = request .. '"'
   end

   local f = io.popen(request)
   local i, max_size = 1, 0
   for l in f:lines() do
      filedata.lines[i] = l
      i = i + 1
   end

   w:refresh()
end

function get_last_lines(w, file)
   local count = w.line_count
   if type(file) == "number" then
      file = w.source_files[file].name
   end
   local fdata = w.data[file]
   if count > #fdata.lines then
      count = #fdata.lines
   end
   local result = { count = count }
   setmetatable(result, { __index = function(t, k)
                                       local nt = fdata.lines
                                       local nk = k + fdata.shift

                                       if nk > #fdata.lines then
                                          return nil
                                       else
                                          return { nt[nk] }
                                       end
                                    end})
   return result
end

function get_result_string(w)
   local data = w:get_last_lines(w.current_file)
   local fdata = w:current_filedata()
   local log_text = ""

   for i = 1, data.count do
      local res = data[i]
      local l, seen = res[1], res[2]

      _, _, l = string.find(l, "%d+ (.+)")

      if #l > w.line_length then
         l = string.sub(l, 1, w.line_length - 3) .. "..."
      end

      log_text = log_text .. l
      if i ~= data.count then
         log_text = log_text .. "\n"
      end
   end

   return log_text
end

function create_kill_menu(w)
   local data = w:get_last_lines(w.current_file)
   local items = {}

   for i = 1, data.count do
      local res = data[i]
      local _, _, pid, name = string.find(res[1], "(%d+) ([^ ]+) ")
      table.insert(items, { name, function()
                                     awful.util.spawn("kill -9 " .. pid, false)
                                  end})
   end

   return awful.menu( { items = items, theme = { width = 150 } } )
end

function show_in_terminal(w)
   local req = w:current_filedata().request
   awful.util.spawn(terminal .. " -e '" .. req .. " | tac | less'")
end

function refresh(w)
   for i = 1, #w.source_files do
      local name = w.source_files[i].name
      name = pango(name,
                   { font = w.title_font,
                     foreground = (w.current_file == i)
                     and w.fg_focus or w.fg_normal } )
      w.ui.title_bar[i]:set_markup(name)
   end

   local log_text = w:get_result_string()
   w.ui.log_textbox:set_markup(pango(log_text, { font = w.font }, true))
end

function calculate_line_count(w, wbox_height)
   local titlebar_font_size = tonumber(string.match(w.title_font, ".+ (%d+)"))
   local real_height = wbox_height - titlebar_font_size
   w.line_count = math.floor(real_height / (theme.get_font_height(w.font) * 1.1)) + 1
end
