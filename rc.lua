local util = require('awful.util')

-- Module for individually configuring Awesome for different machines.
herder = { current = {} }
setmetatable(herder, { __index = function (_, _) return herder.current end })
local rc_folder = util.getdir("config")

local function merge(src, dst)
   for k, v in pairs(src) do
      dst[k] = v
   end
end

local function hostname()
   local f = io.popen("hostname")
   local res = f:read()
   f:close()
   return res
end

local function matches(rule)
   for k, v in pairs(rule) do
      if k == "hostname" then
         if v ~= hostname() then
            return false
         end
      end
      if k == "env_flag" then
         if v ~= os.getenv("AWESOME_HERDER_FLAG") then
            return false
         end
      end
   end
   return true
end

function herder.setup(rules)
   for i = #rules, 1, -1 do
      if matches(rules[i].rule) then
         merge(rules[i].properties, herder.current)
      end
   end
end

function herder.start()
   if herder.current.configs then
      for _, conf_name in ipairs(herder.current.configs) do
         local conf_file = conf_name
         if string.sub(conf_file, 1, 1) ~= "/" then
            conf_file = rc_folder .. "/" .. conf_file
         end
         local len = string.len(conf_file)
         if string.sub(conf_file, len - 3, len) ~= ".lua" then
            conf_file = conf_file .. ".lua"
         end
         print("herder: loading config " .. conf_file)
         dofile(conf_file)
      end
   end
end

-- End of herder module

herder.setup {
   { rule = { hostname = "heather" },
     properties = { configs = { "x220" },
                    hosts = { local_ip = "10.140.28.1",
                              router_ip = "192.168.1.1" } } },
   { rule = { env_flag = "dbg" },
     properties = { debugging = true } },
   { rule = { },
     properties = { configs = { "/etc/xdg/awesome/rc.lua" } } }
}

herder.start()
