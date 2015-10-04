local utility = require('utility')
local wibox = require('wibox')
local scheduler = require('scheduler')
local asyncshell = require('asyncshell')
local awful = require('awful')
local base = require('topjets.base')

-- Module topjets.battery
local battery = base { warning_threshold = 10,
                       devices = {}, data = {} }

local icons

function battery.init(devices)
   battery.devices = devices or { { primary = true, interval = 10 } }

   local l_icon = function (icon_name)
      return base.icon("gpm-battery-" .. icon_name, { 24, 128}, "status")
   end

   icons = { charging = { l_icon('000-charging'),
                          l_icon('020-charging'),
                          l_icon('040-charging'),
                          l_icon('060-charging'),
                          l_icon('080-charging'),
                          l_icon('100-charging') },
             discharging = { l_icon('000'),
                             l_icon('020'),
                             l_icon('040'),
                             l_icon('060'),
                             l_icon('080'),
                             l_icon('charged') },
             full = l_icon('100'),
             missing = l_icon('empty') }

   for i, dev in ipairs(battery.devices) do
      battery.data[i] = { }
      scheduler.register_recurring("topjets.battery" .. i, dev.interval,
                                   function () battery.get_local(i) end)
   end
end

function battery.new()
   return wibox.widget.imagebox()
end

function battery.update(dev_num, stats)
   local dev = battery.devices[dev_num]
   if stats == nil then
      return
   end
   stats.disable_warning = battery.data[dev_num].disable_warning

   if stats.status:match("Discharging") then
      if stats.charge <= battery.warning_threshold and (not stats.disable_warning) then
         naughty.notify({ title = "Battery Warning",
                          text = string.format("Battery is low, %s%% left.", stats.charge),
                          timeout = 0, position = "top_right",
                          icon = icons.discharging[1][2], icon_size = vista.scale(48) })
         battery.data[dev_num].disable_warning = true
      end
      if (battery.data[dev_num] ~= nil) and (battery.data[dev_num].time_disc == nil) then
         stats.time_disc = os.time()
      else
         stats.time_disc = battery.data[dev_num].time_disc
      end
   elseif not stats.status:match("Charging") then
      stats.time_disc = nil
   else
      stats.disable_warning = false
   end
   if dev.primary then
      battery.data.icon = stats.icon
      battery.refresh_all(stats.icon[1])
   end
   battery.data[dev_num] = stats
end

function battery.refresh(w, icon)
   w:set_image(icon)
end

function battery.tooltip()
   local data = battery.data[1]
   local text = "Status\t" .. data.status_text or data.status
   if data.time_disc then
      text = string.format("%s\nLasting\t%s", text, os.date("!%X",os.time() - data.time_disc))
   end
   return { title = string.format("Charge\t%s%%", data.charge),
            text = text,
            icon = battery.data.icon[2], icon_size = vista.scale(48),
            timout = 0 }
end

function battery.get_local(dev_num)
   local info = utility.pslurp("acpi", "*line")
   if not info or string.len(info) == 0 then
      battery.update(dev_num, { status = "Missing", charge = 0,
                                icon = icons.missing })
      return
   end

   local status, charge, time =
      string.match(info, "Battery %d: (%w+), (%d+)%%(.*)")
   time = time:match(",?%s*(.+)")
   charge = tonumber(charge)

   local icon, time_disconnected
   if status:match("Charging") then
      icon = icons.charging[utility.round(charge / 20) + 1]
   elseif status:match("Discharging") then
      icon = icons.discharging[utility.round(charge / 20) + 1]
   else
      icon = icons.full
   end

   battery.update(dev_num,
                  { status = status, charge = charge, time = time,
                    icon = icon, status_text = time or status })
end

return battery
