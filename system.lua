local utility = require('utility')
local asyncshell = require('asyncshell')

local system = { }

-- Network subsystem --
system.network = { hosts = {},
                   interfaces = {},
                   options = { ping_count = 4,
                               ping_timeout = 5,
                               interval = 60 } }

local initialized = false
local hosts_metrics = {}
local callbacks = { latency = {}, connection = {} }
local complete = {}
local interface_connected = {}
local last_iface_connected = nil

local ifconfig_command = "ifconfig %s 2> /dev/null"
local ping_command = "ping -c %d -w %d -q %s"

function system.network.add_latency_callback (fn)
   table.insert(callbacks.latency, fn)
end

function system.network.add_connection_callback (fn)
   table.insert(callbacks.connection, fn)
end

local function check_complete()
   for _, v in pairs(complete) do
      if not v then return end
   end

   for k, _ in pairs(complete) do
      complete[k] = false
   end

   for _, callback in ipairs(callbacks.latency) do
      callback(hosts_metrics)
   end
end

local function ping_callback(f, host)
   local l = f:read()
   if l == nil then
      hosts_metrics[host].loss = 100
      hosts_metrics[host].time = -1
      complete[host] = true
      check_complete()
      return
   end

   -- Skip two lines
   f:read()
   f:read()

   _, _, loss = string.find(f:read(), ", (%d+)%% packet loss")

   if loss ~= "100" then
      _, _, time = string.find(f:read(), "min/avg/max/mdev = [%d%.]+/([%d%.]+)/.*")
   else
      time = -1
   end

   hosts_metrics[host].loss = tonumber(loss)
   hosts_metrics[host].time = tonumber(time)
   complete[host] = true
   check_complete()
end

local function get_iface_type (iface)
   if not iface then
      return "none"
   elseif iface:match("eth.+") then
      return "wired"
   elseif iface:match("wlan.+") then
      return "wireless"
   end
end

local function reping_network()
   for _, host in ipairs(system.network.hosts) do
      asyncshell.request(string.format(ping_command, system.network.options.ping_count,
                                       system.network.options.ping_timeout, host),
                         function(f) ping_callback(f, host) end)
   end
end

local function check_connected ()
   local count = 0
   for _ in pairs(interface_connected) do count = count + 1 end

   if count < #system.network.interfaces then
      return
   end

   local connected_iface = nil
   for _, iface in ipairs(system.network.interfaces) do
      if interface_connected[iface] then
         connected_iface = iface
         break
      end
   end

   local type = get_iface_type(connected_iface)

   for _, callback in ipairs(callbacks.connection) do
      callback(connected_iface, type)
   end

   if last_iface_connected ~= connected_iface then
      reping_network()
   end
end

local function ifconfig_callback (f, iface)
   local t = f:read("*all")
   local type = get_iface_type(iface)
   if t:match("inet %d+%.%d+%.%d+%.%d+ ") then
      interface_connected[iface] = true
   else
      interface_connected[iface] = false
   end
   check_connected()
end

local function requery_network()
   interface_connected = {}

   for _, iface in ipairs(system.network.interfaces) do
      asyncshell.request(string.format(ifconfig_command, iface),
                         function(f) ifconfig_callback(f, iface) end)
   end
end

function system.network.init()
   if initialized then return end
   for _, host in ipairs(system.network.hosts) do
      hosts_metrics[host] = {}
      complete[host] = false
   end
   scheduler.register_recurring("system.network.connection", 10, requery_network)
   scheduler.register_recurring("system.network.latency", system.network.options.interval,
                                reping_network)
   initialized = true
end

return system
