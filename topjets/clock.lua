local wibox = require('wibox')
local l = require('layout')
local scheduler = require('scheduler')
local base = require('topjets.base')

-- Module topjets.clock
local clock = base()

function clock.init()
   scheduler.register_recurring(
      "topjets.clock", 30, function()
         clock.refresh_all(os.date("%a %d"), os.date("%H:%M"))
   end)
end

function clock.new(width)
   local _date = wibox.widget.textbox()
   local _time = wibox.widget.textbox()
   local _widget = l.exact { l.fixed { l.center { _date, horizontal = true },
                                       l.center { _time, horizontal = true },
                                       vertical = true },
                             width = math.max(58, width) }
   _widget.t_date = _date
   _widget.t_time = _time
   return _widget
end

function clock.refresh(w, date, time)
   w.t_date:set_markup(date)
   w.t_time:set_markup(time)
end

return clock
