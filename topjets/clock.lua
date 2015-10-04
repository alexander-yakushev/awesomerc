local wibox = require('wibox')
local l = require('layout')
local scheduler = require('scheduler')
local base = require('topjets.base')
local theme = require("beautiful")
local format = string.format
local utility = require("utility")

-- Module topjets.clock
local clock = base { calendar = { } }

local offset = 0
local widget = nil

function clock.init()
   clock.calendar.text_color = theme.fg_normal
   clock.calendar.today_color = theme.motive
   clock.calendar.font = theme.mono_font
   clock.calendar.icon = base.icon("evolution-calendar2", "apps")
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

function clock.tooltip(w)
   widget = w
   local header, cal_text = clock.calendar.create()
   return { title = header, text = cal_text,
            timeout = 0, icon = clock.calendar.icon.large }
end

-- Calendar

function clock.calendar.create()
   local now = os.date("*t")
   local cal_month = now.month + offset
   local cal_year = now.year
   if cal_month > 12 then
      cal_month = (cal_month % 12)
      cal_year = cal_year + 1
   elseif cal_month < 1 then
      cal_month = (cal_month + 12)
      cal_year = cal_year - 1
   end

   local last_day = tonumber(os.date("%d", os.time({ day = 1, year = cal_year,
                                                     month = cal_month + 1}) - 86400))
   local first_day = os.time({ day = 1, month = cal_month, year = cal_year})
   local first_day_in_week =
      (os.date("%w", first_day) + 6) % 7
   local result = "Mo Tu We Th Fr Sa Su\n"
   for i = 1, first_day_in_week do
      result = result .. "   "
   end

   local this_month = false
   if cal_month == now.month and cal_year == now.year  then
      this_month = true
   end

   for day = 1, last_day do
      local last_in_week = (day + first_day_in_week) % 7 == 0
      local day_str = utility.pop_spaces("", day, 2) .. (last_in_week and "" or " ")
      if this_month and (day == now.day) then
         result = format('%s<span weight="bold" foreground = "%s">%s</span>',
                         result, clock.calendar.today_color, day_str)
      else
         result = result .. day_str
      end
      if last_in_week and day ~= last_day then
         result = result .. "\n"
      end
   end

   local header
   if this_month then
      header = os.date("%a, %d %b %Y")
   else
      header = os.date("%B %Y", first_day)
   end
   return header, format('<span font="%s" foreground="%s">%s</span>',
                         clock.calendar.font, clock.calendar.text_color, result)
end

function clock.calendar.switch_month(dx)
   if dx == 0 then
      offset = 0
   else
      offset = offset + dx
   end
   if widget ~= nil then
      widget:emit_signal("mouse::leave")
      widget:emit_signal("mouse::enter")
   end
end

return clock
