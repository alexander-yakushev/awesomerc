local dbg = require('gears.debug')

-- Module for centralized registration of recurring and deferred
-- actions.
-- Creates a global variable called 'scheduler'.
local scheduler = {}

local event_table = {}

function scheduler.register_recurring(name, interval, func)
   if not event_table[interval] then
      event_table[interval] = { timer = timer({ timeout = interval }),
                                events = {} }
   end
   table.insert(event_table[interval].events, { name = name, func = func })
end

function scheduler.execute_once(delay, func)
   local t = timer({ timeout = delay })
   t:connect_signal("timeout",
                    function()
                       func()
                       t:stop()
                    end)
   t:start()
end

function scheduler.start()
   for interval, event_group in pairs(event_table) do
      event_group.timer:connect_signal("timeout",
                                       function()
                                          for _, e in ipairs(event_group.events) do
                                             e.func()
                                          end
                                       end)
      event_group.timer:start()
      event_group.timer:emit_signal("timeout")
   end
end

function scheduler.print_status()
   dbg.dump(event_table)
end

function scheduler.dump_events()
   return dbg.dump_return(event_table)
end

return scheduler
