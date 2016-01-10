local wibox = require('wibox')
local scheduler = require('scheduler')
local naughty = require('naughty')
local base = require('topjets.base')

local volume = base()

local icons = {}

function volume.init()
   for i, level in ipairs({ "zero", "low", "medium", "high" }) do
      icons[i] = base.icon("audio-volume-" .. level, "status")
   end
   icons.muted = base.icon("audio-volume-muted", "status")

   scheduler.register_recurring("topjets_volume", 20, function()
                                   volume.update(io.popen("amixer get Master"))
   end)
end

function volume.new()
   local w = wibox.widget.imagebox()
   w.inc = volume.inc
   w.dec = volume.dec
   w.mute = volume.mute
   w.unmute = volume.unmute
   w.toggle = volume.toggle
   return w
end

local function get_master_infos(f)
   local state, vol
   for line in f:lines() do
      if string.match(line, "%s%[%d+%%%]%s") ~= nil then
         vol = string.match(line, "%s%[%d+%%%]%s")
         vol = string.gsub(vol, "[%[%]%%%s]","")
      end
      if string.match(line, "%s%[[%l]+%]$") then
         state = string.match(line, "%s%[[%l]+%]$")
         state = string.gsub(state,"[%[%]%%%s]","")
      end
   end
   f:close()
   return state, vol
end

function volume.notify(state, vol, icon)
   volume.notification_id =
      base.notify({ title = "Volume: " .. vol .. "%",
                    text = "State: " .. state,
                    position = tooltip_position, timeout = 3,
                    icon = icon.large, replaces_id = volume.notification_id}).id
end

function volume.update(f, to_notify)
   local state, vol = get_master_infos(f)
   local idx = math.floor(math.min(math.max(tonumber(vol), 0), 99) / 25) + 1
   local naughty_icon

   if state == "off" then
      volume.refresh_all(icons.muted)
      naughty_icon = icons.muted
   else
      volume.refresh_all(icons[idx])
      naughty_icon = icons[idx]
   end

   if to_notify then
      volume.notify(state, vol, naughty_icon)
   end
end

function volume.refresh(w, icon)
   w:set_image(icon.small)
end

function volume.inc()
   volume.update(io.popen("amixer set Master 5%+"), true)
end

function volume.dec()
   volume.update(io.popen("amixer set Master 5%-"), true)
end

function volume.mute()
   volume.update(io.popen("amixer set Master mute"), true)
end

function volume.unmute()
   volume.update(io.popen("amixer set Master unmute"), true)
end

function volume.toggle()
   volume.update(io.popen("amixer set Master toggle"), true)
end

return volume
