local wibox = require('wibox')
local l = require('layout')
local system = require('system')
local base = require('topjets.base')

local network = base()

local custom_hosts = rc.hosts or {}
local hosts = { "github.com", "192.30.252.130",
                custom_hosts.local_ip or "10.0.0.1",
                custom_hosts.router_ip or "192.168.1.1" }
local short_labels = { "", "!DNS: ", "L: ", "R: " }
local labels = { "World", "W/o DNS", "Local", "Router" }
local tooltip = { title = "Network\t\tLatency\t\tLoss" }

local icon_names = { wired = "network-transmit-receive",
                     wireless = "network-wireless-signal-excellent",
                     disconnected = "network-offline" }
local icons = {}

function network.init()
   for k, v in pairs(icon_names) do
      icons[k] = base.icon(v, "status")
   end

   system.network.interfaces = rc.interfaces or { "eth0", "wlan0" }
   system.network.hosts = hosts
   system.network.add_connection_callback(network.connection_callback)
   system.network.add_latency_callback(network.latency_callback)

   system.network.init()
end

function network.new(is_v)
   local network_icon = wibox.widget.imagebox(icons.disconnected.large)
   local network_text = wibox.widget.textbox()

   local _widget =
      l.fixed { l.margin { l.midpoint { network_icon,
                                        vertical = is_v },
                           margin_left = (is_v and 4 or 0), margin_right = vista.scale(4) },
                l.midpoint { network_text,
                             vertical = is_v },
                vertical = is_v }

   _widget.network_icon = network_icon
   _widget.network_text = network_text

   return _widget
end

function network.refresh(w, iface_type, data)
   if iface_type ~= nil then
      w.network_icon:set_image(icons[iface_type].large)
      if iface_type == "none" then
         w.network_text:set_markup("")
      end
   end
   if data ~= nil then
      for i = 1, #hosts do
         if data[hosts[i]].loss ~= 100 then
            w.network_text:set_markup(string.format("%s%d ms", short_labels[i], math.floor(data[hosts[i]].time)))
            return
         end
      end
      w.network_text:set_markup("")
   end
end

function network.update_tooltip(data)
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

function network.tooltip()
   return tooltip
end

function network.connection_callback(_, iface_type)
   tooltip.icon = icons[iface_type].large
   network.refresh_all(iface_type, nil)
end

function network.latency_callback(data)
   network.update_tooltip(data)
   network.refresh_all(nil, data)
end

return network
