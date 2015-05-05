local awful = require("awful")
local format = string.format
local theme = require("beautiful")
local naughty = require("naughty")
local utility = require("utility")

local calendar = { text_color = theme.fg_normal or "#FFFFFF",
                   today_color = theme.fg_focus or "#00FF00",
                   font = theme.font or 'monospace 8' }

local offset = 0

local function create_calendar()
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
                         result, calendar.today_color, day_str)
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
                         calendar.font, calendar.text_color, result)
end

function calendar.hide()
   if calendar.box ~= nil then
      naughty.destroy(calendar.box)
      calendar.box = nil
      offset = 0
   end
end

function calendar.show(inc_offset)
   inc_offset = inc_offset or 0
   local save_offset = offset
   calendar.hide()
   offset = save_offset + inc_offset

   local header, cal_text = create_calendar()
   calendar.box = naughty.notify({ title = header,
                                   text = cal_text,
                                   timeout = 0, hover_timeout = 0.5,
                                   screen = mouse.screen })
end

function calendar.register(widget)
   widget:connect_signal("mouse::enter", function() calendar.show(0) end)
   widget:connect_signal("mouse::leave", calendar.hide)
   widget:buttons(utility.keymap(
                     "LMB", function() awful.util.spawn(software.browser_cmd .. "calendar.google.com", false) end,
                     "WHEELUP", function() calendar.show(-1) end,
                     "WHEELDOWN", function() calendar.show(1) end))
end

return calendar
