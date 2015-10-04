local wibox = require('wibox')
local l = require('layout')
local scheduler = require('scheduler')
local asyncshell = require('asyncshell')
local utility = require('utility')
local lustrous = require('lustrous')
local format = string.format
local json = require('json')
local base = require('topjets.base')

local weather = base {
   cmd = "curl -s 'https://api.forecast.io/forecast/%s/%s,%s?units=si&exclude=minutely,hourly,alerts,flags'",
   lat = private.user.loc.lat, lon = private.user.loc.lon,
   api_key = private.weather.api_key,
   days = 2,
   update_freq = 300,
}

local tooltip = { title = "NO DATA" }

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

local function command ()
   return format (weather.cmd, weather.api_key, weather.lat, weather.lon )
end

local function forecast_line (t, today)
   if t == nil then return "ERROR" end
   local day, temp
   if today then
      day, temp = "Today", format("%d(%d)°C", utility.round(t.temperature),
                                  utility.round(t.apparentTemperature))
   else
      day, temp = os.date("%d.%m", t.time), format("%d/%d°C", utility.round(t.temperatureMin),
                                                   utility.round(t.temperatureMax))
   end
   return format("%s\t%s\t%s %s",
                 day, temp, condition(t.icon).sym, (t.summary or ""))
end

function weather.init()
   for _, t in pairs(cond_mapping) do
      local icon_name = t.icon
      t.icon = base.icon(icon_name, { 24, 128 }, "status")
   end

   scheduler.register_recurring("topjets_weather", 10,
                                function()
                                   if not last_updated or
                                   (os.time() - last_updated > weather.update_freq) then
                                      weather.update()
                                   end
   end)
end

function weather.new(is_v)
   local w_icon = wibox.widget.imagebox()
   local w_text = wibox.widget.textbox()

   local _widget =
      l.fixed { l.margin { l.midpoint { w_icon,
                                        vertical = is_v },
                           margin_left = (is_v and 4 or 0), margin_right = 4 },
                l.midpoint { w_text,
                             vertical = is_v },
                vertical = is_v }

   _widget.w_icon = w_icon
   _widget.w_text = w_text

   return _widget
end

function weather.update_tooltip()
   local data = weather.data
   tooltip.title = forecast_line(data.currently, true)
   tooltip.icon = condition(data.currently.icon).icon[2]

   local text = ""
   for i = 2, weather.days + 1 do
      text = text .. forecast_line(data.daily.data[i])
      if i < weather.days + 1 then
         text = text .. "\n"
      end
   end

   local _, rise, set = lustrous.get_time()
   local len = (set - rise) / 60
   text = text .. format('\n\n☼ %s\t☽ %s\t☉ %s',
                         os.date("%H:%M", rise), os.date("%H:%M", set), math.floor(len / 60) .. ":" .. math.floor(len % 60))
   tooltip.text = text
end

function weather.callback(f)
   weather.data = json.decode(f:read("*all"))
   weather.refresh_all(format("%d°C", utility.round(weather.data.currently.temperature)),
                       cond_mapping[weather.data.currently.icon].icon[2] or cond_mapping.clear.icon[2])
   if weather.data.currently then
      weather.update_tooltip()
   end
   f:close()
   last_updated = os.time()
end

function weather.refresh(w, temp, icon)
   w.w_text:set_markup(temp)
   w.w_icon:set_image(icon)
end

function weather.update()
   asyncshell.request(command(), weather.callback)
end

function weather.tooltip()
   return tooltip
end

return weather
