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
local layout = require("wibox.layout.flex")
local terminal = terminal or "xterm"
local pango = util.pango
local log = require('log')

module("infojets.logwatcher")

default = {}
default.max_line_count = 100

local aclient_bin = "awesomecl"
local watchers = {}

awful.util.spawn('killall inotifywait')

function notify_changed(watcher_id, file_changed)
   watchers[watcher_id]:update(file_changed, true)
end

function add_log_directory(w, dir, files)
   if not string.sub(dir, #dir, #dir) ~= '/' then
      dir = dir .. '/'
   end

   for _, f in ipairs(files) do
      table.insert(w.log_files, { name = dir .. f.file,
                                  mask = f.mask,
                                  ignore = f.ignore })
   end
end

function strip_name(name_with_path)
   local _, _, name = string.find(name_with_path, ".+/(.+)")
   return name
end

function init_widgets(w)
   local ui = {}
   local title_bar = layout.horizontal()
   ui.title_bar = {}

   local mouse_wheel = join(awful.button({ }, 4,
                                         function()
                                            local file = w:current_filedata()
                                            file.shift = file.shift + w.scroll_step
                                            if file.shift + w.line_count > #file.lines then
                                               file.shift = math.max(#file.lines - w.line_count, 0)
                                            end
                                            w:refresh()
                                         end),
                            awful.button({ }, 5,
                                         function()
                                            local file = w:current_filedata()
                                            file.shift = file.shift - w.scroll_step
                                            if file.shift < 0 then
                                               file.shift = 0
                                            end
                                            w:refresh()
                                         end))

   local right_click = awful.button({ }, 3, function()
                                               w:show_in_terminal()
                                            end)
   for i, v in ipairs(w.log_files) do
      local tbox = wibox.widget.textbox()
      local mouse_click = awful.button({ }, 1, function()
                                                  local from_fdata = w:current_filedata()
                                                  from_fdata.last_seen = from_fdata.start - 1
                                                  w.current_file = i
                                                  local to_data = w:current_filedata()
                                                  to_data.shift = 0
                                                  to_data.unread = false
                                                  w:refresh()
                                               end)
      tbox:buttons(join(mouse_click, mouse_wheel))
      table.insert(ui.title_bar, tbox)
      title_bar:add(tbox)
   end

   local log_textbox = wibox.widget.textbox()
   log_textbox:buttons(join(mouse_wheel, right_click))
   log_textbox:set_valign("top")
   ui.log_textbox = log_textbox

   local altogether = wibox.layout.align.vertical()
   altogether:set_first(title_bar)
   altogether:set_second(log_textbox)
   w.ui = ui
   w.widget = altogether
end

function new()
   w = {}
   w.log_files = {}
   w.data = {}
   w.id = #watchers + 1
   w.max_line_count = default.max_line_count
   w.current_file = 1
   w.line_count = 5
   w.font = 'sans 8'
   w.title_font = 'sans 8'
   w.scroll_step = 2
   w.line_length = 30
   w.fg_normal = theme.fg_normal
   w.fg_focus = theme.motive

   watchers[w.id] = w

   w.add_log_directory = add_log_directory
   w.run = run
   w.update = update
   w.get_last_lines = get_last_lines
   w.init_widgets = init_widgets
   w.get_result_string = get_result_string
   w.refresh = refresh
   w.calculate_line_count = calculate_line_count
   w.show_in_terminal = show_in_terminal
   w.current_filedata = current_filedata
   return w
end

function run(w)
   local files = ""
   for i, f in ipairs(w.log_files) do
      files = files .. f.name .. " "
      w.data[f.name] = { lines = {}, start = 1, shift = 0,
                         mask = f.mask, last_seen = 0,
                         ignore = f.ignore }
   end

   local command = string.format("while fchanged=\"`inotifywait -q -e modify " ..
                                 "--format \\\"infojets.logwatcher.notify_changed(%s, '%%w')\\\" %s`\"; " ..
                                 "do echo $fchanged | %s; done",
                              w.id, files, aclient_bin)

   awful.util.spawn("bash -c '" .. string.gsub(command, "'", "'\\''") .. "'")
   w:init_widgets()

   for _, f in ipairs(w.log_files) do
      w:update(f.name)
   end
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
   return w.data[w.log_files[w.current_file].name]
end

function update(w, filename, toggle_unread)
   local filedata = w.data[filename]
   local new_lines = {}
   local request = 'tail -' .. w.max_line_count .. ' ' .. filename .. ' | tac '

   if not filedata then
      return
   end

   if filedata.ignore then
      request = request .. ' | grep -v -E "' .. filedata.ignore[1]
      for i = 2, #filedata.ignore do
         request = request .. "|" .. filedata.ignore[i]
      end
      request = request .. '"'
   end

   local f = io.popen(request)

   local last_idx = filedata.start - 1
   if last_idx == 0 then
      last_idx = #filedata.lines
   end

   for l in f:lines() do
      local masked_l = trasform_line(l, filedata.mask)
      if masked_l == filedata.lines[last_idx] then
         break
      else
         table.insert(new_lines, masked_l)
      end
   end

   if #new_lines == 0 then
      return
   end

   for i = #new_lines, 1, -1 do
      filedata.lines[filedata.start] = new_lines[i]
      filedata.start = filedata.start + 1
      if filedata.start > w.max_line_count then
         filedata.start = 1
      end
   end

   if toggle_unread then
      if filename ~= w.log_files[w.current_file].name then
         filedata.unread = true
      end
   else
      filedata.last_seen = filedata.start - 1
   end

   w:refresh()
end

function get_last_lines(w, file)
   local count = w.line_count
   if type(file) == "number" then
      file = w.log_files[file].name
   end
   local fdata = w.data[file]
   if count > #fdata.lines then
      count = #fdata.lines
   end
   local result = { count = count }
   setmetatable(result, { __index = function(t, k)
                                       local nt = fdata.lines
                                       local nk = fdata.start - count - fdata.shift + k - 1

                                       local seen = true
                                       if fdata.last_seen < fdata.start then
                                          if nk > fdata.last_seen then
                                             seen = false
                                          end
                                       else
                                          if nk < fdata.start or nk > fdata.last_seen then
                                             seen = false
                                          end
                                       end

                                       if nk < 1 then
                                          nk = nk + #fdata.lines
                                       end

                                       if nk > #fdata.lines then
                                          nk = nk - #fdata.lines
                                       end

                                       if nk > #fdata.lines then
                                          return nil
                                       else
                                          return { nt[nk], seen }
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

      if #l > w.line_length then
         l = string.sub(l, 1, w.line_length - 3) .. "..."
      end

      if not seen then
         l = pango(l, { foreground = w.fg_focus }, true)
      else
         l = pango(l, { foreground = w.fg_normal }, true)
      end

      log_text = log_text .. l
      if i ~= data.count then
         log_text = log_text .. "\n"
      end
   end

   return log_text
end

function show_in_terminal(w)
   awful.util.spawn(terminal .. " -e 'less +G " ..
                    w.log_files[w.current_file].name .. "'")
end

function refresh(w)
   for i = 1, #w.log_files do
      local name = w.log_files[i].name
      local decor = w.data[name].unread and "*" or ""
      name = pango(decor .. strip_name(name) .. decor,
                   { font = w.title_font,
                     foreground = (w.current_file == i)
                     and w.fg_focus or w.fg_normal } )
      w.ui.title_bar[i]:set_markup(name)
   end

   local log_text = w:get_result_string()
   w.ui.log_textbox:set_markup(pango(log_text, { font = w.font }))
end

function calculate_line_count(w, wbox_height)
   local titlebar_font_size = tonumber(string.match(w.title_font, ".+ (%d+)"))
   local real_height = wbox_height - titlebar_font_size
   w.line_count = math.floor(real_height / (theme.get_font_height(w.font) * 1.1)) + 1
end
