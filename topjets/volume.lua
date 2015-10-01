local wibox = require('wibox')
local scheduler = require('scheduler')
local naughty = require('naughty')
local base = require('topjets.base')

local volume = base()

local icons = {}

function volume.init()
   for i, level in ipairs({ "zero", "low", "medium", "high" }) do
      icons[i] = base.icon("audio-volume-" .. level, { 24, 128 }, "status")
   end
   icons.muted = base.icon("audio-volume-muted", { 24, 128 }, "status")

   scheduler.register_recurring("topjets_volume", 20, function()
                                   volume.update(io.popen("amixer get Master"))
   end)
end

function volume.new()
   local w = wibox.widget.imagebox()
   w.inc = volume.inc
   w.dec = volume.dec
   w.mute = volume.mute
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
   local n = naughty.notify({ title = "Volume: " .. vol .. "%",
                              text = "State: " .. state,
                              screen = mouse.screen, position = "bottom_right",
                              icon = icon, icon_size = vista.scale(32), timeout = 3,
                              replaces_id = volume.notification_id})
   volume.notification_id = n.id
end

function volume.update(f, to_notify)
   local state, vol = get_master_infos(f)
   local idx = math.floor(math.min(math.max(tonumber(vol), 0), 99) / 25) + 1
   local naughty_icon

   if state == "off" then
      volume.refresh_all(icons.muted[1])
      naughty_icon = icons.muted[2]
   else
      volume.refresh_all(icons[idx][1])
      naughty_icon = icons[idx][2]
   end

   if to_notify then
      volume.notify(state, vol, naughty_icon)
   end
end

function volume.refresh(w, icon)
   w:set_image(icon)
end

function volume.inc()
   volume.update(io.popen("amixer set Master 5%+"), true)
end

function volume.dec()
   volume.update(io.popen("amixer set Master 5%-"), true)
end

function volume.mute()
   volume.update(io.popen("amixer set Master toggle"), true)
end

return volume
