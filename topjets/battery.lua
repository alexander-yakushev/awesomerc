local utility = require('utility')
local wibox = require('wibox')
local iconic = require('iconic')
local scheduler = require('scheduler')
local asyncshell = require('asyncshell')
local awful = require('awful')

-- Module topjets.battery
local battery = { warning_threshold = 10,
                  devices = { } }

local function l_icon(icon_name)
   return { small = iconic.lookup_status_icon(icon_name, { preferred_size = '24x24' }),
            large = iconic.lookup_status_icon(icon_name, { preferred_size = '128x128' }) }
end
local icons

local function round(n)
   local s, f = math.modf(n)
   if f >= 0.5 then return s + 1 else return s end
end

function battery.new(devices)
   if (devices == nil) or (#devices == 0) then
      error("topjets.battery.new: need at least one device")
   end
   battery.devices = devices

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

   local _widget = wibox.widget.imagebox()
   _widget.data = {}

   for i, dev in ipairs(battery.devices) do
      _widget.data[i] = { off = true }
      scheduler.register_recurring("topjets.battery" .. i, dev.interval,
                                   function () dev.update_fn(_widget, i) end)
   end

   utility.add_hover_tooltip(_widget,
                             function(w)
                                local function form_dev_str(i)
                                   local dev = battery.devices[i]
                                   local d = w.data[i]
                                   if not d.off then
                                      return string.format("%s\t%s%%\t\t%s",
                                                           dev.name, d.charge,
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
                                return { title = "Device\t\tCharge\tStatus", text = text,
                                         icon = w.data.icon.large, icon_size = 48,
                                         timout = 0 }
                             end)

   _widget.add_device = function(w, dev) table.insert(battery.devices, dev) end
   return _widget
end

function battery.update(w, dev_num, stats)
   local dev = battery.devices[dev_num]
   if stats == nil then
      w.data[dev_num] = { off = true }
      return
   end
   stats.disable_warning = w.data[dev_num].disable_warning

   if stats.status:match("Discharging") then
      if stats.charge <= battery.warning_threshold and (not stats.disable_warning) then
	 naughty.notify({ title    = "Battery Warning",
			  text     = dev.name .. " battery is low, " .. stats.charge .."%" .. " left.",
			  timeout  = 0, position = "top_right",
                          icon = icons.discharging[1].large, icon_size = 32,
                          run = function(n)
                             w.data[dev_num].disable_warning = true
                             naughty.destroy(n)
                          end})
      end
   else
      stats.disable_warning = false
   end
   if dev.primary then
      w:set_image(stats.icon.small)
      w.data.icon = stats.icon
   end
   w.data[dev_num] = stats
end

function battery.get_local(w, dev_num)
   local dev = battery.devices[dev_num]
   local info = utility.pslurp("acpi", "*line")
   if not info or string.len(info) == 0 then
      battery.update(w, dev_num, { status = "Missing", charge = 0,
                                   icon = icons.missing })
      return
   end

   local status, charge, time =
      string.match(info, "Battery %d: (%w+), (%d+)%%(.*)")
   time = time:match(",?%s*(.+)")
   charge = tonumber(charge)

   local icon
   if status:match("Charging") then
      icon = icons.charging[round(charge / 20) + 1]
   elseif status:match("Discharging") then
      icon = icons.discharging[round(charge / 20) + 1]
   else
      icon = icons.full
   end

   battery.update(w, dev_num,
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

function battery.get_via_adb(w, dev_num)
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
                         battery.update(w, dev_num, res)
                         if not was_connected then
                            awful.util.spawn("adb disconnect", false)
                         end
                         f:close()
                           end)
end

return setmetatable(battery, { __call = function(_, ...) return battery.new(...) end})
