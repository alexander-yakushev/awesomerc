local wibox = require('wibox')
local system = require('system')
local iconic = require('iconic')
local utility = require('utility')

local network = {}

local format = "%s%d ms"
local hosts = { "github.com", "195.24.232.203", "128.39.32.2" }
local short_labels = { "", "^DNS: ", "L: " }
local labels = { "World", "W/o DNS", "Local" }
local tooltip = {
   title = "Network\t\tLatency\t\tLoss",
   timeout = 0,
   icon_size = 48 }

local icon_names = { connected = "network-transmit-receive",
                     wireless = "network-wireless-signal-excellent",
                     disconnected = "network-offline" }

local function connection_callback(w, type)
   local icon
   if type == "wired" then
      icon = "connected"
   elseif type == "wireless" then
      icon = "wireless"
   else
      icon = "disconnected"
   end

   w.network_icon:set_image(icons.small[icon])
   tooltip.icon = icons.large[icon]
   if type == "none" then
      w.network_text:set_markup("")
   end
end

local function update_tooltip (data)
   tooltip.text = ""
   for i = 1, #hosts do
      local lat = data[hosts[i]].time
      if lat == -1 then
         lat = "∞\t"
      elseif lat < 1 then
         lat = math.floor(lat * 1000) .. " μs"
      else
         lat = math.floor(lat) .. " ms"
      end
      tooltip.text = tooltip.text .. string.format("%s\t\t%s\t\t%d%%",
                                                   labels[i], lat, data[hosts[i]].loss)
      if i < #hosts then
         tooltip.text = tooltip.text .. "\n"
      end
   end
end

local function latency_callback(w, data)
   update_tooltip(data)
   for i = 1, #hosts do
      if data[hosts[i]].loss ~= 100 then
         w.network_text:set_markup(string.format(format, short_labels[i], data[hosts[i]].time))
         return
      end
   end
   w.network_text:set_markup("")
end

function network.new()
   icons = { small = {}, large = {} }
   for k, v in pairs(icon_names) do
      icons.small[k] = iconic.lookup_status_icon(v, { preferred_size = "128x128" })
      icons.large[k] = iconic.lookup_status_icon(v, { preferred_size = "128x128" })
   end

   local network_icon = wibox.widget.imagebox()
   local network_text = wibox.widget.textbox()

   local _widget = wibox.layout.fixed.vertical()
   local icon_centered = wibox.layout.align.horizontal()
   icon_centered:set_middle(wibox.layout.constraint(network_icon, 'exact', 40, 40))
   _widget:add (icon_centered)
   local val_centered = wibox.layout.align.horizontal()
   val_centered:set_middle(network_text)
   _widget:add (val_centered)

   _widget.network_icon = network_icon
   _widget.network_text = network_text

   network_icon:set_image(icons.disconnected)
   network_text:set_markup("")

   system.network.interfaces = { "eth0", "wlan0" }
   system.network.add_connection_callback(function(_, type)
                                             connection_callback(_widget, type)
                                          end)
   system.network.hosts = hosts
   system.network.add_latency_callback(function(data)
                                          latency_callback(_widget, data)
                                       end)

   system.network.init()

   utility.add_hover_tooltip(_widget,
                             function(w)
                                return tooltip
                             end)
   return _widget
end

return setmetatable(network, { __call = function(_, ...) return network.new(...) end})
