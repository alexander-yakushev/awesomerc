local wibox = require('wibox')
local system = require('system')
local iconic = require('iconic')

local network = {}

local format = " %d ms"
local hosts = { "github.com", "195.24.232.203", "128.39.32.2" }
local labels = { "W", "W w/o DNS", "L" }

local iconic_args = { preferred_size = "24x24" }

local function data_callback(w, data)
   for i = 1, #hosts do
      if data[hosts[i]].loss ~= 100 then
         w.network_text:set_markup(string.format(format, data[hosts[i]].time))
         w.network_icon:set_image(icons.connected)
         return
      end
   end
   w.network_icon:set_icon(icons.disconnected)
   w.network_text:set_markup("")
end

function network.new()
   icons = { connected = iconic.lookup_status_icon("network-transmit-receive", iconic_args),
             disconnected = iconic.lookup_status_icon("network-offline", iconic_args) }

   local network_icon = wibox.widget.imagebox()
   local network_text = wibox.widget.textbox()

   local _widget = wibox.layout.fixed.horizontal()
   _widget:add (network_icon)
   _widget:add (network_text)

   _widget.network_icon = network_icon
   _widget.network_text = network_text

   network_icon:set_image(icons.disconnected)
   network_text:set_markup("")

   system.network.hosts = hosts
   system.network.add_callback(function(data)
                                  data_callback(_widget, data)
                               end)
   system.network.init()

   return _widget
end

return setmetatable(network, { __call = function(_, ...) return network.new(...) end})
