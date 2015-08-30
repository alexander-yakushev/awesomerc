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

local function xrandr_menu()
   local xrandr = function(args)
      return function()
         util.spawn("xrandr " .. args)
      end
   end
   return {
      { "&LVDS1", xrandr("--output LVDS1 --auto --output VGA1 --off") },
      { "&VGA1", xrandr("--output LVDS1 --off --output VGA1 --auto") },
      { "LV&DS1+VGA1", {
           { "&Right of", xrandr("--output VGA1 --auto --right-of LVDS1 --auto") },
           { "&Below", xrandr("--output VGA1 --auto --below LVDS1 --auto") } } } }
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
                         { '&display', xrandr_menu() } },
                      theme = { width = 150 } }
   local m = menu(mainmenu)
   m:show()
end

return smartmenu
