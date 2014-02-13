-- Useful reusable functions

local awful = require('awful')
local naughty = require('naughty')

-- Module "utility"
local utility = {}

function utility.slurp(file, mode)
   local handler = io.open(file, 'r')
   local result = handler:read(mode or "*all")
   handler:close()
   return result
end

function utility.pslurp(command, mode)
   local handler = io.popen(command)
   local result = handler:read(mode or "*all")
   handler:close()
   return result
end

local userdir = userdir or utility.pslurp("echo $HOME", "*line")

function utility.run_once(prg, times)
   if not prg then
      do return nil end
   end
   times = times or 1
   count_prog =
      tonumber(awful.util.pread('ps aux | grep "' .. string.gsub(prg, ":", " ") .. '" | grep -v grep | wc -l')) or 0
   if times > count_prog then
      for l = count_prog, times-1 do
         awful.util.spawn_with_shell(prg)
      end
   end
end

local function subs_home(command)
   return string.gsub(command, "~", userdir)
end

function utility.autorun(apps, run_once_apps)
   for _, app in ipairs(apps or {}) do
      print(app)
      awful.util.spawn_with_shell(subs_home(app), true)
   end
   for _, app in ipairs(run_once_apps or {}) do
      utility.run_once(subs_home(app), 1)
   end
end

function utility.pop_spaces(s1,s2,maxsize)
   local sps = ""
   for i = 1, maxsize-string.len(s1)-string.len(s2) do
      sps = sps .. " "
   end
   return s1 .. sps .. s2
end

function utility.append_table(what, to_what, overwrite)
   for k, v in pairs(what) do
      if type(k) ~= "number" then
         if overwrite or not to_what[k] then
            to_what[k] = v
         end
      else
         table.insert(to_what, v)
      end
   end
end

-- *** Internal calc function *** ---
function utility.calc(result)
   naughty.notify( { title = "Awesome calc",
                     text = "Result: " .. result,
                     timeout = 5})
end

function utility.view_non_empty(step, s)
   local s = mouse.screen or 1
   -- The following makes sure we don't go into an endless loop
   -- if no clients are visible. I guess that case could be handled better,
   -- but meh
   local num_tags = #awful.tag.gettags(s)
   for i = 1, num_tags do
     awful.tag.viewidx(step, s)
     if #awful.client.visible(s) > 0 then
        return
     end
  end
end

function utility.view_first_empty(s)
   local s = mouse.screen or 1
   -- The following makes sure we don't go into an endless loop
   -- if no clients are visible. I guess that case could be handled better,
   -- but meh
   local num_tags = #awful.tag.gettags(s)
   for i = 1, num_tags do
      awful.tag.viewidx(1, s)
      if #awful.client.visible(s) == 0 then
         return
      end
   end
end

function utility.spawn_in_terminal(program)
   awful.util.spawn(software.terminal_cmd .. program)
end

function utility.add_hover_tooltip(w, f)
   w:connect_signal("mouse::enter",
                    function(c)
                       local nt = f(w)
                       nt.screen = mouse.screen
                       nt.position = "bottom_right"
                       w.hover_notification = naughty.notify(nt)
                    end)
   w:connect_signal("mouse::leave",
                    function(c)
                       if w.hover_notification ~= nil then
                          naughty.destroy(w.hover_notification)
                          w.hover_notification = nil
                       end
                    end)
end

return utility
