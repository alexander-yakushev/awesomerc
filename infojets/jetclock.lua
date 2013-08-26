-- Clock rendered by cairo.
-- Found somewhere on the web.
-- Modified by: A. Yakushev &lt;yakushev.alex@gmail.com&gt;

local os = os
local math = math
local io = io
local type = type
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local string = string
local table = table
local lgi = require('lgi')
local util = require("infojets.util")
local cairo = lgi.cairo
local wibox = require("wibox")
local naughty = require("naughty")
require("asyncshell")
local asyncshell = asyncshell
local scheduler = scheduler

module("infojets.jetclock")

bg_color      = "#222222CC"
ring_bg_color = "#AAAAAA33"
ring_fg_color = "#AAAAAAFF"
hand_color    = "#CCCCCCCC"
hand_motive   = "#76eec6CC"
text_hlight   = "#76eec6"
text_font     = "Helvetica 11"
text_limit    = 19
shift_str     = "    "
shape   = "circle"

local function init_parts()
   rings = {
      decor1 = {
         hard_value = 0.5,
         radius = 0.77,
         thickness = 7,
         start_angle = -90,
         end_angle = 90,
         show = true
      },
      decor2 = {
         hard_value = 0.5,
         radius = 0.77,
         thickness = 7,
         start_angle = 90,
         end_angle = 270,
         show = true
      },
      marks = {
         hard_value = -1,
         sector_count = 12,
         fill_ratio = 0.15,
         radius = 0.7,
         thickness = 7,
         start_angle = 0,
         end_angle = 360,
         show = true
      }
   }

   hands = {
      hour = {
         value = function()
                    return tonumber(os.date("%I")) * 60 + tonumber(os.date("%M"))
                 end,
         max = 720,
         color  = hand_color,
         length = 0.6,
         width  = 5,
         show = true
      },
      minute = {
         value = "%M",
         max = 60,
         color  = hand_color,
         length = 0.85,
         width  = 3,
         show = true
      },
      second = {
         value = "%S",
         max = 60,
         color  = hand_color,
         length = 0.85,
         width  = 1,
         show = false
      },
      hour_remind = {
         value = nil,
         max = 720,
         color = hand_motive,
         length = 0.6,
         width = 5,
         show = false
      }
   }
end

function get_val(val)
   local res
   if type(val) == "string" then
      return tonumber(os.date(val))
   elseif type(val) == "function" then
      return val()
   else
      error("E: jetclock: wrong value used in clock configuration: " .. val)
   end
end

local function prepend_zero(num, count)
   local count, actual = count or 2, string.len(tostring(num))
   local res = num
   for i = actual, count - 1 do
      res = "0" .. res
   end
   return res
end

function init_widgets(w)
   local ui = {}
   local clock_box = wibox.layout.fixed.vertical()
   local info_box = wibox.layout.align.horizontal()

   local shift = wibox.widget.textbox()
   shift:set_markup(shift_str)
   local clock = wibox.widget.imagebox()
   clock:set_resize(false)

   local info = wibox.widget.textbox()
   info:set_valign("top")

   w.weather = { today = { cond = "Really bad", temp = -30 },
                 forecast = { { date = "05.02", cond = "Even worse", temp_min = -50, temp_max = -40 },
                              { date = "06.02", cond = "Worst ever", temp_min = -90, temp_max = -90 } } }
   clock_box:add(clock)
   info_box:set_left(shift)
   info_box:set_middle(info)
   clock_box:add(info_box)
   ui.clock = clock
   ui.info = info
   w.ui = ui

   w.widget = clock_box
end

function draw_ring(w, cr, t, pt)
   local clock_r, xc, yc = w.geometry.radius, w.geometry.x, w.geometry.y
   local ring_r, ring_w, sa, ea =
      pt.radius, pt.thickness, pt.start_angle, pt.end_angle
   local bg = pt.bg_color or ring_bg_color
   local fg = pt.fg_color or ring_fg_color

   local angle_0 = sa * (2 * math.pi / 360) - math.pi / 2
   local angle_f = ea * (2 * math.pi / 360) - math.pi / 2
   local t_arc   = t * (angle_f - angle_0)

   -- Draw background ring
   cr:arc(xc, yc, ring_r * clock_r, angle_0, angle_f)
   cr:set_source_rgba(util.color_to_r_g_b_a(bg))
   cr:set_line_width(ring_w)
   cr:stroke(c)

   -- Draw indicator ring
   cr:set_source_rgba(util.color_to_r_g_b_a(fg))
   if not pt.sector_count then
      cr:arc(xc, yc, ring_r * clock_r, angle_0, angle_0 + t_arc)
      cr:stroke()
   else
      local step = (angle_f - angle_0) / pt.sector_count
      local sec_width = step * pt.fill_ratio
      angle_0, angle_f = angle_0 - sec_width / 2, angle_f - sec_width / 2
      for i = 1, pt.sector_count do
         cr:arc(xc, yc, ring_r*clock_r, angle_0, angle_0 + sec_width)
         cr:stroke()
         angle_0 = angle_0 + step
      end
   end
end

function draw_triangle_clock(w, cr, t, pt)
   local clock_r, xc, yc = w.geometry.radius, w.geometry.x, w.geometry.y

   local stroke_length = 0.2
   local width = 3

   local c_distance, x, y, xd, yd

   local angle, b_angle = 0

   local from_angle =
      function(angle)
         if angle > 2 * math.pi then
            angle = angle - 2 * math.pi
         end
         local c_distance
         if angle <= math.pi * 2 / 3 then
            c_distance = clock_r * math.sin(math.pi / 6) / math.sin(math.pi / 6 + angle)
         elseif angle < math.pi * 4 / 3 then
            c_distance = clock_r * math.sin(math.pi / 6) / math.sin(- math.pi / 2 - angle)
         else
            c_distance = clock_r * math.sin(math.pi / 6) / math.sin(angle - math.pi * 7 / 6)
         end

         local x = xc + c_distance * math.sin(angle)
         local y = yc - c_distance * math.cos(angle)

         return c_distance, x, y
      end

   for i = 1, 12 do
      c_distance, x, y = from_angle(angle)

      b_angle = math.pi + angle

      xd = x + stroke_length * c_distance * math.sin(b_angle)
      yd = y - stroke_length * c_distance * math.cos(b_angle)

      cr:move_to(x, y)
      cr:line_to(xd, yd)
      cr:set_line_cap("square")
      cr:set_line_width(width)
      local r, g, b, a = util.color_to_r_g_b_a(ring_bg_color)
      cr:set_source_rgba(r, g, b, a)
      cr:stroke()

      angle = angle + math.pi / 6
   end

   for _, hand in pairs(hands) do
      if hand.show then
         angle = get_val(hand.value) / hand.max * 2 * math.pi
         c_distance, x, y = from_angle(angle)

         b_angle = math.pi + angle

         xd = x + (1 - hand.length) * c_distance * math.sin(b_angle)
         yd = y - (1 - hand.length) * c_distance * math.cos(b_angle)

         cr:move_to(xd, yd)
         cr:line_to(xc, yc)
         cr:set_line_cap("round")
         cr:set_line_width(hand.width)
         local r, g, b, a = util.color_to_r_g_b_a(hand.color)
         cr:set_source_rgba(r, g, b, a)
         cr:stroke()
      end
   end
end

function draw_clock_hand(w, cr, hand)
   local clock_r, xc, yc = w.geometry.radius, w.geometry.x, w.geometry.y
   local secs, mins, hours, secs_arc, mins_arc, hours_arc
   local x, y

   local arc = get_val(hand.value) / hand.max * 2 * math.pi

   -- Draw hand
   x = xc + hand.length * clock_r * math.sin(arc)
   y = yc - hand.length * clock_r * math.cos(arc)
   cr:move_to(xc, yc)
   cr:line_to(x, y)
   cr:set_line_cap("round")
   cr:set_line_width(hand.width)
   local r, g, b, a = util.color_to_r_g_b_a(hand.color)
   cr:set_source_rgba(r, g, b, a)
   cr:stroke()
end

function new(width, height, info_height, radius)
   init_parts()
   local w = {}

   w.geometry = { radius = 100,
                  x = width / 2, y = height / 2,
                  clock_width = width, clock_height = height,
                  info_height = info_height, radius = radius }
   init_widgets(w)

   w.weather_bin = "weatherfc"

   w.draw = draw
   w.draw_ring = draw_ring
   w.draw_clock_hand = draw_clock_hand
   w.set_sizes = set_sizes
   w.run = run
   w.remind = remind
   w.notify_reminder = notify_reminder
   w.update_weather = create_weather_callback(w)
   return w
end

local function cut_limit(s)
   if not s then
      return s
   end
   if #s > text_limit then
      return string.sub(s, 1, text_limit)
   end
   return s
end

function draw(w)
   now_draw = not now_draw
   local cs = cairo.ImageSurface.create('ARGB32', w.geometry.clock_width,
                                        w.geometry.clock_height)
   local cr = cairo.Context.create(cs)

   -- Check if reminder is due
   if w.reminder then
      local hour, minute = os.date("%H"), os.date("%M")
      if hour == w.reminder.hour and minute == w.reminder.minute then
         w:notify_reminder()
         hands.hour_remind.show = false
         w.reminder = nil
      end
   end

   if shape == "circle" then
      -- Draw rings
      for _, v in pairs(rings) do
         if v.show then
            if v.hard_value then
               pct = v.hard_value
            else
               pct = get_val(v.value) / v.max
            end
            w:draw_ring(cr, pct, v)
         end
      end
      -- Draw hands
      for _, v in pairs(hands) do
         if v.show then
            w:draw_clock_hand(cr, v)
         end
      end
   else
      draw_triangle_clock(w, cr)
   end

   -- Update info
   local text = ""

   if w.weather then
      text = text .. string.format("%s %s (%s°C)\n",
                                   util.pango("Today:\t",
                                              { foreground = text_hlight }),
                                   cut_limit(w.weather.today.cond),
                                   w.weather.today.temp)
      if w.weather.forecast then
         for _, v in ipairs(w.weather.forecast) do
            text = text .. string.format("%s %s (%s/%s°C)\n",
                                         util.pango(v.date .. ":\t",
                                                    { foreground = text_hlight }),
                                         cut_limit(v.cond), v.temp_min, v.temp_max)
         end
      end
   end

   if w.reminder then
      text = text .. string.format("%s\t %s",
                                   util.pango(string.format("%s:%s", prepend_zero(w.reminder.hour),
                                                            prepend_zero(w.reminder.minute)),
                                              { foreground = text_hlight }),
                                   w.reminder.text)
   end
   w.ui.info:set_markup(util.pango(text, { font = text_font }))

   w.ui.clock.image = cs
   w.ui.clock:emit_signal("widget::updated")
end

function run(w)
   scheduler.register_recurring("infojets_clock", 30, function() w:draw() end)
   scheduler.register_recurring("infojets_weather", 600,
                                function()
                                   asyncshell.request(w.weather_bin, w.update_weather)
                                end)
end

function set_sizes(w, new_radius, new_width, new_height)
   w.geometry = { radius = new_radius,
                  x = new_width / 2,
                  y = new_height / 2 }
end

function remind(w, when, what)
   local hour, minute, text
   if what then
      _, _, hour, minute = string.find(when, "(%d+):(%d+)")
      text = what
   else
      _, _, hour, minute, text = string.find(when, "(%d+):(%d+)%s+(.+)")
   end
   w.reminder = { text = text,
                  hour = hour,
                  minute = minute }
   hands.hour_remind.value = function()
                                return (hour % 12) * 60 + minute
                             end
   hands.hour_remind.show = true
   naughty.notify( { title = "Jetclock remainder",
                     text = "Notification will appear at "
                        .. hour .. ":" .. minute })
   w:draw()
end

function notify_reminder(w)
   naughty.notify({ preset = naughty.config.presets.critical,
                    title = "Jetclock reminder",
                    text = w.reminder.text,
                    timeout = 0 })
end

function create_weather_callback(w)
   return
   function(file)
      local day, month, desc, temp, tempx
      local i = 0
      local m = "[^,]+"
      for l in file:lines() do
         if string.sub(l,1,1) ~= "#" then
            i = i + 1
            if i == 1 then
               _, _, temp, desc =
                  string.find(l, string.format("%s,(%s),%s,%s,(%s),.*", m, m, m, m, m))
               w.weather.today = { cond = desc or "", temp = temp or ""}
               w.weather.forecast = {}
            elseif i >= 3 then
               _, _, month, day, tempx, temp, desc =
                  string.find(l, string.format("%s+-(%s+)-(%s+),(%s),%s,(%s),%s,%s,%s,%s,%s,%s,%s,(%s),.*",
                                               "%d", "%d", "%d", m, m, m, m, m, m, m, m, m, m, m))
               table.insert(w.weather.forecast, { date = day .. "." .. month,
                                                  cond = desc,
                                                  temp_min = temp,
                                                  temp_max = tempx })
            end
         end
      end
      file:close()
      w:draw()
   end
end