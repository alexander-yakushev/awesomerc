local debug = require('gears.debug')
local naughty = naughty

-- Module "log"
local log = {}

log.d_return = debug.dump_return

log.d = debug.dump

function log.n(data, tag)
   if not naughty then
      naughty = require("naughty")
   end
   naughty.notify( { title = tag or "ETDP",
                     text = log.d_return(data),
                     timeout = 0,
                     screen = mouse.screen})
end

function log.e(message, title)
   if title then
      print("[ERROR]", title .. " : " .. message)
   else
      print("[ERROR]", message)
   end
   if not naughty then
      naughty = require("naughty")
   end
   naughty.notify( { preset = naughty.config.presets.critical,
                     title = title or "Error",
                     text = message,
                     timeout = 0,
                     screen = mouse.screen})
end

function log.p(...)
   print("[DEBUG]", ...)
end

return log
