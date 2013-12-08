local utility = require('utility')
local wibox = require('wibox')
local iconic = require('iconic')

-- Module topjets.battery
local battery = {}

local pref_size = '24x24'
local icons

local function round(n)
   local s, f = math.modf(n)
   if f >= 0.5 then return s + 1 else return s end
end

function battery.new()
   icons = { charging = { iconic.lookup_status_icon('gpm-battery-000-charging', { preferred_size = pref_size }),
                          iconic.lookup_status_icon('gpm-battery-020-charging', { preferred_size = pref_size }),
                          iconic.lookup_status_icon('gpm-battery-040-charging', { preferred_size = pref_size }),
                          iconic.lookup_status_icon('gpm-battery-060-charging', { preferred_size = pref_size }),
                          iconic.lookup_status_icon('gpm-battery-080-charging', { preferred_size = pref_size }),
                          iconic.lookup_status_icon('gpm-battery-100-charging', { preferred_size = pref_size }) },
             discharging = { iconic.lookup_status_icon('gpm-battery-000', { preferred_size = pref_size }),
                             iconic.lookup_status_icon('gpm-battery-020', { preferred_size = pref_size }),
                             iconic.lookup_status_icon('gpm-battery-040', { preferred_size = pref_size }),
                             iconic.lookup_status_icon('gpm-battery-060', { preferred_size = pref_size }),
                             iconic.lookup_status_icon('gpm-battery-080', { preferred_size = pref_size }),
                             iconic.lookup_status_icon('gpm-battery-charged', { preferred_size = pref_size }) },
             full = iconic.lookup_status_icon('gpm-battery-100', { preferred_size = pref_size }) }

   local _widget = wibox.widget.imagebox()

   if battery.update(_widget) then
      scheduler.register_recurring("topjets.battery", 10,
                                   function () battery.update(_widget) end)
      utility.add_hover_tooltip(_widget,
                                function(w)
                                   return { title = w.data.charge .. "% - " .. w.data.status,
                                            text = w.data.time, icon = w.data.icon, icon_size = 32 }
                                end)
   end
   return _widget
end

function battery.update(w)
   local info = utility.pslurp("acpi", "*line")
   if not info or string.len(info) == 0 then
      return false
   end

   local _, _, status, charge, time =
      string.find(info, "Battery %d: (%w+), (%d+)%%(.*)")
   local icon

   time = time:match(",?%s*(.+)")
   charge = tonumber(charge)

   if status:match("Charging") then
      icon = icons.charging[round(charge / 20) + 1]
   elseif status:match("Discharging") then
      icon = icons.discharging[round(charge / 20) + 1]
      if charge <= 10 then
	 naughty.notify({ title    = "Battery Warning",
			  text     = "Battery low! " .. charge .."%" .. " left!",
			  timeout  = 5,
                          icon = battery.icon, icon_size = 32,
			  position = "top_right" })
      end
   else
      icon = icons.full
   end
   w:set_image(icon)
   w.data = { status = status, charge = charge, time = time, icon = icon }
   return true
end

return setmetatable(battery, { __call = function(_, ...) return battery.new(...) end})
