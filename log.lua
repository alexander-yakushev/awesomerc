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
                     text = log.d_return(data, tag or "data"),
                     timeout = 0,
                     screen = mouse.screen})
end

function log.p(...)
   print("Debug print", ...)
end

return log