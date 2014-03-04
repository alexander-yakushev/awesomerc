local menu = require('awful.menu')
local picturesque = require('picturesque')

local smartmenu = {}

--- Flashmanager part

local fm_script = "sudo /home/unlogic/scripts/flashmanager"

local function flashmanager()
   local f = io.popen(fm_script)
   local actions = { theme = { width = 300 } }
   local i = 1
   for l in f:lines() do
      table.insert(actions, { string.format("[&%i] %s", i, l),
                              fm_script .. " " .. i })
      i = i + 1
   end
   return actions
end

---

local function netpower(action)
   return "sudo /home/unlogic/scripts/netpower " .. action
end

---

function smartmenu.show()
   local mainmenu = { items = {
                         { '&awesome', { { "change &wallpaper", picturesque.change_image },
                                         { "restart", awesome.restart },
                                         { "quit", awesome.quit } } },
                         { '&flashmanager', flashmanager() },
                         { '&network', { { "&Both", netpower("on on") },
                                         { "&Ethernet", netpower("on off") },
                                         { "&Wireless", netpower("off on") },
                                         { "&Neither", netpower("off off") } } } },
                         theme = { width = 150 } }
   local m = menu(mainmenu)
   m:show()
end

return smartmenu
