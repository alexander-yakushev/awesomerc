local wibox = require('wibox')
local scheduler = require('scheduler')
local asyncshell = require('asyncshell')
local utility = require('utility')
local iconic = require('iconic')
local lustrous = require('lustrous')
local format = string.format
local json = require('json')

local weather = {
   cmd = "curl -s 'https://api.forecast.io/forecast/%s/%s,%s?units=si&exclude=minutely,hourly,alerts,flags'",
   lat = private.user.loc.lat, lon = private.user.loc.lon,
   api_key = private.weather.api_key,
   days = 2,
   update_freq = 300,
}

local last_updated = nil

local cond_mapping = {
   ["clear-day"]           = { sym = "☀", icon = 'weather-clear' },
   ["clear-night"]         = { sym = "☽", icon = 'weather-clear-night' },
   ["partly-cloudy-day"]   = { sym = "☁", icon = 'weather-few-clouds' },
   ["partly-cloudy-night"] = { sym = "☁", icon = 'weather-few-clouds-night' },
   ["cloudy"]              = { sym = "☁", icon = 'weather-overcast' },
   ["wind"]                = { sym = "☁", icon = 'weather-overcast' },
   ["fog"]                 = { sym = "☁", icon = 'weather-fog.png' },
   ["rain"]                = { sym = "☂", icon = 'weather-showers' },
   ["sleet"]               = { sym = "☃", icon = 'weather-snow.png' },
   ["snow"]                = { sym = "☃", icon = 'weather-snow.png' },
}

local function condition(icon_name)
   return cond_mapping[icon_name] or cond_mapping["clear-day"]
end

local function round(temp)
   return math.floor(temp + 0.5)
end

local function command ()
   return format (weather.cmd, weather.api_key, weather.lat, weather.lon )
end

local function forecast_line (t, today)
   if t == nil then return "ERROR" end
   local day, temp
   if today then
      day, temp = "Today", format("%d(%d)°C", round(t.temperature),
                                  round(t.apparentTemperature))
   else
      day, temp = os.date("%d.%m", t.time), format("%d/%d°C", round(t.temperatureMin),
                                                   round(t.temperatureMax))
   end
   return format("%s\t%s\t%s %s",
                 day, temp, condition(t.icon).sym, (t.summary or ""))
end

function weather.update_tooltip (w)
   weather.tooltip.title = forecast_line(w.weather.currently, true)
   weather.tooltip.icon = condition(w.weather.currently.icon).icon

   local text = ""
   for i = 2, weather.days + 1 do
      text = text .. forecast_line(w.weather.daily.data[i])
      if i < weather.days + 1 then
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
   w.weather = json.decode(file:read("*all"))
   weather.w_text:set_markup(format("%d°C", round(w.weather.currently.temperature)))
   weather.w_icon:set_image(cond_mapping[w.weather.currently.icon].icon or cond_mapping.clear.icon)
   if w.weather.currently then
      weather.update_tooltip(weather._widget)
   end
   file:close()
   last_updated = os.time()
end

function weather.refresh()
   asyncshell.request(command(), weather.callback)
end

function weather.new()
   for _, t in pairs(cond_mapping) do
      local icon_name = t.icon
      t.icon = iconic.lookup_status_icon(icon_name, { preferred_size = "128x128" })
   end

   weather.w_icon = wibox.widget.imagebox()
   weather.w_text = wibox.widget.textbox()

   weather._widget = wibox.layout.fixed.vertical()
   local icon_centered = wibox.layout.align.horizontal()
   icon_centered:set_middle(wibox.layout.constraint(weather.w_icon, 'exact', 40, 40))
   weather._widget:add (icon_centered)
   local val_centered = wibox.layout.align.horizontal()
   val_centered:set_middle(weather.w_text)
   weather._widget:add (val_centered)

   weather.tooltip = {
      title = "NO DATA",
      timeout = 0,
      icon_size = 48 }

   scheduler.register_recurring("topjets_weather", 10,
                                function()
                                   if not last_updated or
                                      (os.time() - last_updated > weather.update_freq) then
                                      weather.refresh()
                                   end
                                end)

   utility.add_hover_tooltip(weather._widget,
                             function(w)
                                return weather.tooltip
                             end)

   return weather._widget
end

return setmetatable(weather, { __call = function(_, ...) return weather.new(...) end})
