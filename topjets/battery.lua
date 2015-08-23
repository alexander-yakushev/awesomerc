local utility = require('utility')
local wibox = require('wibox')
local iconic = require('iconic')
local scheduler = require('scheduler')
local asyncshell = require('asyncshell')
local awful = require('awful')
local base = require('topjets.base')

-- Module topjets.battery
local battery = base { warning_threshold = 10,
                       devices = {}, data = {} }

local icons

function battery.init(devices)
   if (devices == nil) or (#devices == 0) then
      error("topjets.battery.new: need at least one device")
   end
   battery.devices = devices

   local l_icon = function (icon_name)
      return base.icon(icon_name, { 24, 128}, "status")
   end
   icons = { charging = { l_icon('gpm-battery-000-charging'),
                          l_icon('gpm-battery-020-charging'),
                          l_icon('gpm-battery-040-charging'),
                          l_icon('gpm-battery-060-charging'),
                          l_icon('gpm-battery-080-charging'),
                          l_icon('gpm-battery-100-charging') },
             discharging = { l_icon('gpm-battery-000'),
                             l_icon('gpm-battery-020'),
                             l_icon('gpm-battery-040'),
                             l_icon('gpm-battery-060'),
                             l_icon('gpm-battery-080'),
                             l_icon('gpm-battery-charged') },
             full = l_icon('gpm-battery-100'),
             missing = l_icon('gpm-battery-empty') }

   for i, dev in ipairs(battery.devices) do
      battery.data[i] = { off = true }
      scheduler.register_recurring("topjets.battery" .. i, dev.interval,
                                   function () dev.update_fn(i) end)
   end
end

function battery.new()
   return wibox.widget.imagebox()
end

function battery.update(dev_num, stats)
   local dev = battery.devices[dev_num]
   if stats == nil then
      battery.data[dev_num] = { off = true }
      return
   end
   stats.disable_warning = battery.data[dev_num].disable_warning

   if stats.status:match("Discharging") then
      if stats.charge <= battery.warning_threshold and (not stats.disable_warning) then
         naughty.notify({ title    = "Battery Warning",
                          text     = dev.name .. " battery is low, " .. stats.charge .."%" .. " left.",
                          timeout  = 0, position = "top_right",
                          icon = icons.discharging[1][2], icon_size = 32,
                          run = function(n)
                             battery.data[dev_num].disable_warning = true
                             naughty.destroy(n)
                          end})
      end
      if (battery.data[dev_num] ~= nil) and (battery.data[dev_num].time_disc == nil) then
         stats.time_disc = os.time()
      else
         stats.time_disc = w.data[dev_num].time_disc
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
   local function form_dev_str(i)
      local dev = battery.devices[i]
      local d = battery.data[i]
      local onbattery = "\t"
      if d.time_disc ~= nil then
         onbattery = os.date("!%X",os.time() - d.time_disc)
      end
      if not d.off then
         return string.format("%s\t%s%%\t\t%s\t%s",
                              dev.name, d.charge,
                              onbattery .. "\t",
                              d.status_text or d.status)
      end
   end
   local text = form_dev_str(1)
   for i = 2, #battery.devices do
      local s = form_dev_str(i)
      if s ~= nil then
         text = text .. "\n" .. s
      end
   end
   return { title = "Device\t\tCharge\tOn battery\tStatus", text = text,
            icon = battery.data.icon[2], icon_size = 48,
            timout = 0 }
end

function battery.get_local(dev_num)
   local dev = battery.devices[dev_num]
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

function battery.get_adb_devices()
   local f = asyncshell.demand("adb devices", 1)
   if not f then
      return {}
   end
   local devs = {}
   f:read() -- Skip first
   for l in f:lines() do
      local dev = l:match("(%d+%.%d+%.%d+%.%d+:%d+).*")
      if dev ~= nil then
         devs[dev] = true
      end
   end
   return devs
end

function battery.get_via_adb(dev_num)
   local dev = battery.devices[dev_num]
   local dir = dev.dir or "/sys/class/power_supply/battery"
   local cmd, was_connected = "", true
   if not battery.get_adb_devices()[dev.addr] then
      cmd = "adb connect " .. dev.addr .. "; sleep 1;"
      was_connected = false
   end
   cmd = string.format("%sadb -s %s shell cat %s/%s %s/%s",
                       cmd, dev.addr, dir, dev.charge, dir, dev.status)
   asyncshell.request(cmd, function(f)
                         local res = nil
                         local charge = f:read()
                         local status = f:read()
                         if charge ~= nil then
                            res = { charge = tonumber(charge),
                                    status = status }
                         end
                         battery.update(dev_num, res)
                         if not was_connected then
                            awful.util.spawn("adb disconnect", false)
                         end
                         f:close()
   end)
end

return battery
