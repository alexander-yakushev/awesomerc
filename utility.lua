-- Useful reusable functions

local awful = require('awful')
local naughty = require('naughty')

-- Module "utility"
local utility = {}

function utility.slurp(file, mode)
   local handler
   if type(file) == "userdata" then
      handler = file
   else
      handler = io.open(file, 'r')
   end
   if handler ~= nil then
      local result = handler:read(mode or "*all")
      handler:close()
      return result
   end
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

function utility.keymap(...)
   local mouse_buttons = { LMB = 1, MMB = 2, RMB = 3, WHEELUP = 4, WHEELDOWN = 5 }
   local arg = {...}
   local i = 1
   local result
   if type(arg[1]) ~= "string" then
      result = arg[1]
      i = 2
   else
      result = {}
   end
   while i < #arg do
      local key = arg[i]
      local cb = arg[i+1]
      local modifiers = {}
      local make = awful.key
      for cons in string.gmatch(key, "[^-]+") do
         table.insert(modifiers, cons)
      end
      key = modifiers[#modifiers]
      modifiers[#modifiers] = nil
      for i, mod in ipairs(modifiers) do
         if mod == "C" then
            modifiers[i] = "Control"
         elseif mod == "S" then
            modifiers[i] = "Shift"
         elseif mod == "M" then
            modifiers[i] = "Mod4"
         end
      end
      if mouse_buttons[key] ~= nil then
         key = mouse_buttons[key]
         make = awful.button
      end
      result = awful.util.table.join(result, make(modifiers, key, cb))
      i = i + 2
   end
   return result
end

function utility.refocus()
   if client.focus then client.focus:raise() end
end

function utility.round(n)
   local s, f = math.modf(n)
   if f >= 0.5 then return s + 1 else return s end
end

function utility.conversion(req)
   local weight = { kg = 1, lbs = 2.20462, oz = 35.274 }
   local distance = { m = 1, ft = 3.28, ml = 0.00062137 }
   local all_units = { weight, distance }
   local val, metric = string.match(req, "([%d%.]+)%s*(.+)")
   val = tonumber(val)

   -- Special case for feet inches
   local feet, inches = string.match(req, "(%d+)'(%d+)")
   if feet ~= nil then
      val = feet + (inches / 12)
      metric = "ft"
   end

   local result = ""
   local units = nil
   for _, u in ipairs(all_units) do
      if u[metric] ~= nil then
         units = u
      end
   end
   if units ~= nil then
      for m, q in pairs(units) do
         if m ~= metric then
            if m == "ft" then
               local feet = val * units[m] / units[metric]
               result = string.format("%s%d'%d\"\n", result, math.floor(feet), utility.round((feet - math.floor(feet)) * 12))
            else
               result = string.format("%s%4.2f\t%s\n", result, val * units[m] / units[metric], m)
            end
         end
      end
      result = result:sub(1, #result-1)
      naughty.notify({ title = string.format("%4.2f\t%s", val, metric),
                       text = result, timeout = 0 })
   end
end

return utility
