local awful = require('awful')
awful.rules = require('awful.rules')
local vista = require('vista')

local rulez = { rules_file = awful.util.getdir("config") .. "/saved_rules.lua" }

function table.pprint(tbl, spc)
   local result = ""
   local pr = function(txt) result = result .. txt end
   local spaces = function(n)
      local result = ""
      for i = 1, n do result = result .. " " end
      return result
   end
   local cut = function(i) result = result:sub(1, #result - i) end
   if type(tbl) == "table" then
      pr("{ ")
      spc = (spc or 0) + 2
      local empty = true
      if #tbl > 0 then
         empty = false
         for i, v in ipairs(tbl) do
            pr(table.pprint(v, spc))
            pr(",\n" .. spaces(spc))
         end
      end
      for k, v in pairs(tbl) do
         if not (type(k) == "number" and k <= #tbl) then
            empty = false
            if type(k) == "string" then
               pr(k)
            else
               pr("[")
               pr(table.pprint(k))
               pr("]")
            end
            pr(" = ")
            pr(table.pprint(v, spc))
            pr(",\n" .. spaces(spc))
         end
      end
      if not empty then cut(spc+2) end
      pr(" }")
   elseif type(tbl) == "string" then
      pr(string.format('"%s"', tbl))
   else
      pr(tostring(tbl))
   end
   return result
end

function table.read(f)
   local ftables, err = loadfile(f)
   if err then
      error("Failed reading rules file: " .. f)
   end
   local tables = ftables()
   return tables
end

local function existing_screen(s)
   s = s or vista.primary
   if s == "primary" then
      return vista.primary
   elseif s == "secondary" then
      return vista.secondary
   elseif s > screen.count() then
      return 1
   else
      return s
   end
end

local function screen_role(s)
   s = s or mouse.screen
   if s == vista.primary then
      return "primary"
   elseif s == vista.secondary then
      return "secondary"
   end
end

function rulez.apply()
   local t = {}
   for _, v in ipairs(rulez.static_rules) do
      table.insert(t, v)
   end
   for _, rule in ipairs(rulez.saved_rules) do
      local scr = existing_screen(rule.properties.screen)
      local tag = rule.properties.tag
      if tag ~= nil then
         rule.properties.tag = tags[scr][tag]
         if rule.properties.screen ~= nil then
            rule.properties.screen = scr
         end
      end
      table.insert(t, rule)
   end
   awful.rules.rules = t
end

function rulez.init(static_rules)
   rulez.static_rules = static_rules or {}
   rulez.saved_rules = table.read(rulez.rules_file)
   if rulez.saved_rules == nil then
      rulez.saved_rules = {}
   end
   rulez.apply()
end

local function tag_id(tag)
   local index = nil
   for scr = 1, screen.count() do
      for i, v in ipairs(tags[scr]) do
         if v == tag then
            index = i
            break
         end
      end
   end
   return index
end

function rulez.persist()
   local rules_data = {}
   for _, v in ipairs(awful.rules.rules) do
      if (type(v) == "table") and not (v.rule.class == nil) then
         local ov = { rule = v.rule,
                      properties = { floating = v.properties.floating,
                                     tag = tag_id(v.properties.tag) } }
         if v.properties.screen ~= nil then
            ov.properties.screen = screen_role(v.properties.screen)
         end
         table.insert(rules_data, ov)
      end
   end
   local f = io.open(rulez.rules_file, "w")
   f:write("return\n")
   f:write(table.pprint(rules_data))
   f:close()
end

function rulez.remember(c)
   local c = c or client.focus
   if c == nil then
      return
   end
   local class = c.class
   -- find this rule
   local rule
   for _, v in ipairs(awful.rules.rules) do
      if v.rule.class == class then
         rule = v
         if v.properties.tag ~= nil then
            fixed = true
         end
         break
      end
   end
   if rule == nil then
      rule = { rule = { class = class }, properties = {} }
      table.insert(awful.rules.rules, rule)
   end

   local tag = c:tags()[1]

   if (rule.properties.tag == nil or rule.properties.tag ~= tag
       or rule.properties.screen == nil or rule.properties.screen ~= mouse.screen) then
      rule.properties.tag = tag
      rule.properties.screen = mouse.screen
      local s_role = screen_role()
      naughty.notify({ title = "Client: " .. class, screen = mouse.screen,
                       text  = string.format("Bound to tag %d%s",
                                             tag_id(tag),
                                             (s_role and " of " .. s_role .. " screen" or "")) })
   else
      rule.properties.tag = nil
      rule.properties.screen = nil
      naughty.notify({ title = "Client: " .. class, screen = mouse.screen,
                       text  = string.format("Unbound from tag %d", tag_id(tag)) })
   end
   rulez.persist()
end

return rulez
