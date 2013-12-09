local wibox = require('wibox')
local scheduler = require('scheduler')
local asyncshell = require('asyncshell')
local utility = require('utility')
local iconic = require('iconic')
local lustrous = require('lustrous')
local format = string.format

local weather = {
   cmd = "curl -s 'http://api.worldweatheronline.com/free/v1/weather.ashx?q=%s&format=csv&num_of_days=%s&key=%s' 2> /dev/null",
   city = private.user.city .. "," .. private.user.country,
   api_key = private.weather.api_key,
   days = 3
}

local cond_mapping = {
   ["Clear"] = { sym = "☀", sym_night = "☽", icon = 'weather-clear', icon_night = 'weather-clear-night' },
   ["Sunny"] = { sym = "☀", sym_night = "☽", icon = 'weather-clear', icon_night = 'weather-clear-night' },
   ["Partly Cloudy"] = { sym = "☁", icon = 'weather-few-clouds', icon_night = 'weather-few-clouds-night' },
   ["Overcast"] = { sym = "☁", icon = 'weather-overcast' },
   ["Cloudy"] = { sym = "☁", icon = 'weather-overcast' },
   ["[Ff]og"] = { sym = "☁", icon = 'weather-fog.png' },
   ["Mist"] = { sym = "☁", icon = 'weather-fog.png' },
   ["outbreaks"] = { sym = "☂", icon = 'weather-storm' },
   ["Patchy rain"] = { sym = "☂", icon = 'weather-showers-scattered' },
   ["Light rain"] = { sym = "☂", icon = 'weather-showers-scattered' },
   ["light rain"] = { sym = "☂", icon = 'weather-showers-scattered' },
   ["Moderate rain"] = { sym = "☂", icon = 'weather-showers' },
   ["Heavy rain"] = { sym = "☂", icon = 'weather-showers' },
   ["rain shower"] = { sym = "☂", icon = 'weather-showers' },
   ["drizzle"] = { sym = "☂", icon = 'weather-showers-scattered' },
   ["with thunder"] = { sym = "☂", icon = 'weather-storm.png' },
   ["Patchy sleet"] = { sym = "☃", icon = 'weather-snow.png' },
   ["snow"] = { sym = "☃", icon = 'weather-snow.png' },
   ["[Ss]leet"] = { sym = "☃", icon = 'weather-snow.png' }
}

local function command ()
   return format (weather.cmd, weather.city, weather.days, weather.api_key)
end

local function widget_line (t)
   return format(" %s%s°C",
                 not t.icon and t.cond or "",
                 t.temp)
end

local function forecast_line (t, today)
   if t == nil then return "ERROR" end
   local day, temp
   if today then
      day, temp = "Today", t.temp .. "°C  "
   else
      day, temp = t.date, t.temp_min .. "/" .. t.temp_max .. "°C"
   end
   return format("%s\t%s\t%s%s",
                 day, temp,
                 (t.icon and (t.icon .. " ") or ""),
                 (t.cond or ""))
end

function weather.update_tooltip (w)
   weather.tooltip.title = forecast_line(w.weather.today, true)
   weather.tooltip.icon = w.weather.today.large_icon

   local text = ""
   for i, t in ipairs(w.weather.forecast) do
      text = text .. forecast_line(t)
      if i < #w.weather.forecast then
         text = text .. "\n"
      end
   end

   local _, rise, set = lustrous.get_time()
   local len = (set - rise) / 60
   text = text .. format('\n\n☼ %s\t☽ %s\t☉ %s',
                         os.date("%H:%M", rise), os.date("%H:%M", set), math.floor(len / 60) .. ":" .. len % 60)
   weather.tooltip.text = text
end

function weather.callback (file)
   local w = weather._widget
   local i = 0
   local m = "[^,]+"
   w.weather = {}
   for l in file:lines() do
      if l:sub(1, 1) ~= "#" then
         i = i + 1
         if i == 1 then
            local temp, desc =
               l:match(format("%s,(%s),%s,%s,(%s),.*", m, m, m, m, m))
            w.weather.today = { cond = desc or "", temp = temp or "" }
            weather.process_entry(w.weather.today, true)
            weather.w_text:set_markup(widget_line(w.weather.today))
            weather.w_icon:set_image(w.weather.today.small_icon)
            w.weather.forecast = {}
         elseif i >= 3 then
            local month, day, tempx, temp, desc =
               l:match(format("%s+-(%s+)-(%s+),(%s),%s,(%s),%s,%s,%s,%s,%s,%s,%s,(%s),.*",
                              "%d", "%d", "%d", m, m, m, m, m, m, m, m, m, m, m))
               local t = { date = day .. "." .. month,
                           cond = desc,
                           temp_min = temp,
                           temp_max = tempx }
               weather.process_entry(t)
               table.insert(w.weather.forecast, t)
         end
      end
   end
   file:close()
   if w.weather.today then
      weather.update_tooltip(weather._widget)
   end
end

function weather.process_entry (t, today)
   for k, v in pairs(cond_mapping) do
      if t.cond:match(k) then
         t.icon = v.sym
         t.large_icon = v.icon
         t.small_icon = v.icon_small
         if today and lustrous.get_time() == "night" then
            if v.icon_night then
               t.large_icon = v.icon_night
               t.small_icon = v.icon_night_small
            end
            if v.sym_night then
               t.icon = v.sym_night
            end
         end
         break
      end
   end
end

function weather.refresh()
   asyncshell.request(command(), weather.callback)
end

function weather.new()
   for _, t in pairs(cond_mapping) do
      local icon_name = t.icon
      t.icon = iconic.lookup_status_icon(icon_name, { preferred_size = "128x128" })
      t.icon_small = iconic.lookup_status_icon(icon_name, { preferred_size = "24x24" })
      if t.icon_night then
         local icon_name_night = t.icon_night
         t.icon_night = iconic.lookup_status_icon(icon_name_night, { preferred_size = "128x128" })
         t.icon_night_small = iconic.lookup_status_icon(icon_name_night, { preferred_size = "24x24" })
      end
   end

   weather.w_icon = wibox.widget.imagebox()
   weather.w_text = wibox.widget.textbox()

   weather._widget = wibox.layout.fixed.horizontal()
   weather._widget:add(weather.w_icon)
   weather._widget:add(weather.w_text)

   weather.tooltip = {
      title = "NO DATA",
      timeout = 0,
      icon_size = 48 }

   scheduler.register_recurring("topjets_weather", 60, weather.refresh)

   utility.add_hover_tooltip(weather._widget,
                             function(w)
                                return weather.tooltip
                             end)

   return weather._widget
end

return setmetatable(weather, { __call = function(_, ...) return weather.new(...) end})
