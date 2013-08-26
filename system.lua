local utility = require('utility')
local asyncshell = require('asyncshell')

local system = { }

-- Network subsystem --
system.network = { hosts = {},
                   options = { ping_count = 4,
                               ping_timeout = 5,
                               interval = 60 } }

local initialized = false
local hosts_metrics = {}
local callbacks = {}
local complete = {}

local ping_command = "ping -c %d -w %d -q %s"

function system.network.add_callback(fn)
   table.insert(callbacks, fn)
end

local function check_complete()
   for _, v in pairs(complete) do
      if not v then return end
   end

   for k, _ in pairs(complete) do
      complete[k] = false
   end

   for _, callback in ipairs(callbacks) do
      callback(hosts_metrics)
   end
end

local function ping_callback(f, host)
   local l = f:read()
   if l == nil then
      hosts_metrics[host].loss = 100
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
   end

   hosts_metrics[host].loss = tonumber(loss)
   hosts_metrics[host].time = tonumber(time)
   complete[host] = true
   check_complete()
end

local function requery_network()
   for _, host in ipairs(system.network.hosts) do
      asyncshell.request(string.format(ping_command, system.network.options.ping_count,
                                       system.network.options.ping_timeout, host),
                         function(f) ping_callback(f, host) end)
   end
end

function system.network.init()
   if initialized then return end
   for _, host in ipairs(system.network.hosts) do
      hosts_metrics[host] = {}
      complete[host] = false
   end
   scheduler.register_recurring("system.network", system.network.options.interval,
                                requery_network)
   initialized = true
end

return system