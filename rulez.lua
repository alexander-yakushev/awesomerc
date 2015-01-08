local awful = require('awful')

local rulez = {}

local function exportstring(s)
   return string.format("%q", s)
end

--// The Save Function
function table.save(tbl, filename)
   local charS,charE = "   ","\n"
   local file,err = io.open( filename, "wb" )
   if err then return err end

   -- initiate variables for save procedure
   local tables,lookup = { tbl },{ [tbl] = 1 }
   file:write( "return {"..charE )

   for idx,t in ipairs( tables ) do
      file:write( "-- Table: {"..idx.."}"..charE )
      file:write( "{"..charE )
      local thandled = {}

      for i,v in ipairs( t ) do
         thandled[i] = true
         local stype = type( v )
         -- only handle value
         if stype == "table" then
            if not lookup[v] then
               table.insert( tables, v )
               lookup[v] = #tables
            end
            file:write( charS.."{"..lookup[v].."},"..charE )
         elseif stype == "string" then
            file:write(  charS..exportstring( v )..","..charE )
         elseif stype == "number" then
            file:write(  charS..tostring( v )..","..charE )
         end
      end

      for i,v in pairs( t ) do
         -- escape handled values
         if (not thandled[i]) then

            local str = ""
            local stype = type( i )
            -- handle index
            if stype == "table" then
               if not lookup[i] then
                  table.insert( tables,i )
                  lookup[i] = #tables
               end
               str = charS.."[{"..lookup[i].."}]="
            elseif stype == "string" then
               str = charS.."["..exportstring( i ).."]="
            elseif stype == "number" then
               str = charS.."["..tostring( i ).."]="
            end

            if str ~= "" then
               stype = type( v )
               -- handle value
               if stype == "table" then
                  if not lookup[v] then
                     table.insert( tables,v )
                     lookup[v] = #tables
                  end
                  file:write( str.."{"..lookup[v].."},"..charE )
               elseif stype == "string" then
                  file:write( str..exportstring( v )..","..charE )
               elseif stype == "number" then
                  file:write( str..tostring( v )..","..charE )
               end
            end
         end
      end
      file:write( "},"..charE )
   end
   file:write( "}" )
   file:close()
end

function table.load(sfile)
   local ftables,err = loadfile( sfile )
   if err then return _,err end
   local tables = ftables()
   for idx = 1,#tables do
      local tolinki = {}
      for i,v in pairs( tables[idx] ) do
         if type( v ) == "table" then
            tables[idx][i] = tables[v[1]]
         end
         if type( i ) == "table" and tables[i[1]] then
            table.insert( tolinki,{ i,tables[i[1]] } )
         end
      end
      -- link indices
      for _,v in ipairs( tolinki ) do
         tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
      end
   end
   return tables[1]
end

-- ChillCode

local function existing_screen(s)
   if s > screen.count() then
      return 1
   else
      return s
   end

end

function rulez.apply()
   local t = {}
   for _, v in ipairs(rulez.static_rules) do
      table.insert(t, v)
   end
   for _, v in ipairs(rulez.dynamic_rules) do
      local tdata = v.properties.tag
      if tdata ~= nil then
         table.insert(t, { rule = v.rule, properties = { tag = tags[existing_screen(tdata[1])][tdata[2]] }})
      end
   end
   awful.rules.rules = t
end

function rulez.init(datafile)
   local datafile = datafile or (awful.util.getdir("cache") .. "/dynamic_rules")
   rulez.file = datafile
   rulez.static_rules = awful.rules.rules
   rulez.dynamic_rules = table.load(datafile)
   if rulez.dynamic_rules == nil then
      rulez.dynamic_rules = {}
   end
   rulez.apply()
end

function rulez.persist()
   table.save(rulez.dynamic_rules, rulez.file)
end

function rulez.remember(c)
   local c = c or client.focus
   if c == nil then
      return
   end
   local class = c.class
   -- find this rule
   local rule
   for _, v in ipairs(rulez.dynamic_rules) do
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
      table.insert(rulez.dynamic_rules, rule)
   end

   local ctag = c:tags()[1]
   local index = nil;
   for i, v in ipairs(tags[c.screen]) do
      if v == ctag then
         index = i
         break
      end
   end

   local tdata = rule.properties.tag

   if (tdata == nil) or (tdata[1] ~= c.screen) or (tdata[2] ~= index) then
      rule.properties.tag = { c.screen, index }
      naughty.notify({ title = "Client: " .. class,
                       text  = "Bound to tag " .. index .. " on screen " .. c.screen })
   else
      rule.properties.tag = nil
      naughty.notify({ title = "Client: " .. class,
                       text  = "Unbound from screen " .. c.screen })
   end
   rulez.persist()
   rulez.apply()
end

return rulez
