local menu = require('awful.menu')
local util = require('awful.util')

local smartmenu = {}
local scripts_dir = util.getdir("config") .. "/scripts/"

local fm_script = scripts_dir .. "flashmanager"
local np_script = scripts_dir .. "netpower"

local fm_script_fmt = "sudo %s/scripts/flashmanager %s"

local function flashmanager()
   if not util.file_readable(fm_script) then
      return
   end
   local f = io.popen("sudo " .. fm_script)
   if (f ~= nil) then
      local actions = { theme = { width = 300 } }
      local i = 1
      for l in f:lines() do
         table.insert(actions, { string.format("[&%i] %s", i, l),
                                 fm_script .. " " .. i})
         i = i + 1
      end
      return actions
   end
end

local function netpower(action)
   return string.format("sudo %s %s", np_script, action)
end

function smartmenu.show()
   local mainmenu = { items = {
                         { '&awesome', { { "restart", awesome.restart },
                                         { "quit", awesome.quit } } },
                         { '&flashmanager', flashmanager() },
                         { '&network', { { "&Both", netpower("on on") },
                                         { "&Ethernet", netpower("on off") },
                                         { "&Wireless", netpower("off on") },
                                         { "&Neither", netpower("off off") } } },
                         { '&music', function() utility.spawn_in_terminal("ncmpc") end },
                         { '&display', vista.xrandr.menu() } },
                      theme = { width = 150 } }
   local m = menu(mainmenu)
   m:show()
end

return smartmenu
